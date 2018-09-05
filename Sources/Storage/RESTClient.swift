//
//  RESTClient.swift
//  LeanCloud
//
//  Created by Tang Tianyong on 3/30/16.
//  Copyright © 2016 LeanCloud. All rights reserved.
//

import Foundation
import Alamofire

/**
 LeanCloud REST client.

 This class manages requests for LeanCloud REST API.
 */
class RESTClient {
    /// HTTP Method.
    enum Method: String {
        case get
        case post
        case put
        case delete

        /// Get Alamofire corresponding method
        var alamofireMethod: Alamofire.HTTPMethod {
            switch self {
            case .get:    return .get
            case .post:   return .post
            case .put:    return .put
            case .delete: return .delete
            }
        }
    }

    /// Data type.
    enum DataType: String {
        case object   = "Object"
        case pointer  = "Pointer"
        case relation = "Relation"
        case geoPoint = "GeoPoint"
        case bytes    = "Bytes"
        case date     = "Date"
    }

    /// Header field name.
    class HeaderFieldName {
        static let id         = "X-LC-Id"
        static let signature  = "X-LC-Sign"
        static let session    = "X-LC-Session"
        static let production = "X-LC-Prod"
        static let userAgent  = "User-Agent"
        static let accept     = "Accept"
    }

    /// REST API version.
    static let apiVersion = "1.1"

    /// Default timeout interval of each request.
    static let defaultTimeoutInterval: TimeInterval = NSURLRequest().timeoutInterval

    /// REST client shared instance.
    static let sharedInstance = RESTClient()

    /// Default completion dispatch queue.
    static let defaultCompletionDispatchQueue = DispatchQueue(label: "LeanCloud.RESTClient.Completion", attributes: .concurrent)

    /// Shared session manager.
    static var requestManager: Alamofire.SessionManager = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = defaultTimeoutInterval
        return SessionManager(configuration: configuration)
    }()

    /// User agent of SDK.
    static let userAgent = "LeanCloud-Swift-SDK/\(version)"

    /// Signature of each request.
    static var signature: String {
        let timestamp = String(format: "%.0f", 1000 * Date().timeIntervalSince1970)
        let hash = (timestamp + LCApplication.default.key).md5String.lowercased()

        return "\(hash),\(timestamp)"
    }

    /// Common REST request headers.
    static var commonHeaders: [String: String] {
        var headers: [String: String] = [
            HeaderFieldName.id:        LCApplication.default.id,
            HeaderFieldName.signature: self.signature,
            HeaderFieldName.userAgent: self.userAgent,
            HeaderFieldName.accept:    "application/json"
        ]

        if let sessionToken = LCUser.current?.sessionToken {
            headers[HeaderFieldName.session] = sessionToken.value
        }

        return headers
    }

    /// REST host for current service region.
    static var host: String {
        switch LCApplication.default.region {
        case .cn: return "api.leancloud.cn"
        case .us: return "us-api.leancloud.cn"
        }
    }

    /**
     Get endpoint of object.

     - parameter object: The object from which you want to get the endpoint.

     - returns: The endpoint of object.
     */
    static func endpoint(_ object: LCObject) -> String {
        return endpoint(object.actualClassName)
    }

    /**
     Get eigen endpoint of object.

     - parameter object: The object from which you want to get the eigen endpoint.

     - returns: The eigen endpoint of object.
     */
    static func eigenEndpoint(_ object: LCObject) -> String? {
        guard let objectId = object.objectId else {
            return nil
        }

        return "\(endpoint(object))/\(objectId.value)"
    }

    /**
     Get endpoint for class name.

     - parameter className: The class name.

     - returns: The endpoint for class name.
     */
    static func endpoint(_ className: String) -> String {
        switch className {
        case LCUser.objectClassName():
            return "users"
        case LCRole.objectClassName():
            return "roles"
        default:
            return "classes/\(className)"
        }
    }

    /**
     Get absolute REST API URL string for endpoint.

     - parameter endpoint: The REST API endpoint.

     - returns: An absolute REST API URL string.
     */
    static func absoluteURLString(_ endpoint: String) -> String {
        return "https://\(self.host)/\(self.apiVersion)/\(endpoint)"
    }

    /**
     Merge headers with common headers.

     Field in `headers` will overrides the field in common header with the same name.

     - parameter headers: The headers to be merged.

     - returns: The merged headers.
     */
    static func mergeCommonHeaders(_ headers: [String: String]?) -> [String: String] {
        var result = commonHeaders

        headers?.forEach { (key, value) in result[key] = value }

        return result
    }

    /**
     Creates a request to REST API and sends it asynchronously.

     - parameter method:                    The HTTP Method.
     - parameter endpoint:                  The REST API endpoint.
     - parameter parameters:                The request parameters.
     - parameter headers:                   The request headers.
     - parameter completionDispatchQueue:   The dispatch queue in which the completion handler will be called. By default, it's a concurrent queue.
     - parameter completionHandler:         The completion callback closure.

     - returns: A request object.
     */
    static func request(
        _ method: Method,
        _ endpoint: String,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        completionDispatchQueue: DispatchQueue = defaultCompletionDispatchQueue,
        completionHandler: @escaping (LCResponse) -> Void)
        -> LCRequest
    {
        let method    = method.alamofireMethod
        let urlString = absoluteURLString(endpoint)
        let headers   = mergeCommonHeaders(headers)
        var encoding: ParameterEncoding!

        switch method {
        case .get: encoding = URLEncoding.default
        default:   encoding = JSONEncoding.default
        }

        let request = requestManager.request(urlString, method: method, parameters: parameters, encoding: encoding, headers: headers).validate()
        log(request: request)

        request.responseJSON(queue: completionDispatchQueue) { response in
            log(response: response, request: request)
            completionHandler(LCResponse(response: response))
        }

        return LCSingleRequest(request: request)
    }

    /**
     Create request for error.

     - parameter error:                     The error object.
     - parameter completionDispatchQueue:   The dispatch queue in which the completion handler will be called. By default, it's a concurrent queue.
     - parameter completionHandler:         The completion callback closure.

     - returns: A request object.
     */
    static func request(
        error: Error,
        completionDispatchQueue: DispatchQueue = defaultCompletionDispatchQueue,
        completionHandler: @escaping (LCBooleanResult) -> Void) -> LCRequest
    {
        return request(object: error, completionDispatchQueue: completionDispatchQueue) { error in
            completionHandler(.failure(error: error))
        }
    }

    static func request<T>(
        object: T,
        completionDispatchQueue: DispatchQueue = defaultCompletionDispatchQueue,
        completionHandler: @escaping (T) -> Void) -> LCRequest
    {
        completionDispatchQueue.async {
            completionHandler(object)
        }

        return LCSingleRequest(request: nil)
    }

    static func log(response: DataResponse<Any>, request: Request) {
        Logger.shared.debug("\n\n\(response.lcDebugDescription(request))\n")
    }

    static func log(request: Request) {
        Logger.shared.debug("\n\n\(request.lcDebugDescription)\n")
    }
}

extension Request {

    var lcDebugDescription : String {
        var curl: String = debugDescription

        if curl.hasPrefix("$ ") {
            let startIndex: String.Index = curl.index(curl.startIndex, offsetBy: 2)
            curl = String(curl[startIndex...])
        }

        let taskIdentifier = task?.taskIdentifier ?? 0
        let message = "------ BEGIN LeanCloud HTTP Request\n" +
                      "task: \(taskIdentifier)\n" +
                      "curl: \(curl)\n" +
                      "------ END"
        return message
    }

}

extension DataResponse {

    func lcDebugDescription(_ request : Request) -> String {
        var body : Any

        switch value {
        case let value as [String : AnyObject]:
            /* Print pertty JSON string. */
            body = LCDictionary(unsafeObject: value).jsonString
            break
        default:
            body = value ?? ""
            break
        }

        let taskIdentifier = request.task?.taskIdentifier ?? 0
        let message = "------ BEGIN LeanCloud HTTP Response\n" +
                      "task: \(taskIdentifier)\n" +
                      "body: \(body)\n" +
                      "------ END"
        return message
    }

}
