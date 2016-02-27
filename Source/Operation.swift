//
//  Operation.swift
//  LeanCloud
//
//  Created by Tang Tianyong on 2/25/16.
//  Copyright © 2016 LeanCloud. All rights reserved.
//

import Foundation

/**
 Operation arithmetic.

 Define the available arithmetic for operation.
 */
protocol OperationArithmetic {
    /* Stub protocol */
}

extension LCObject {

    /**
     Operation.

     Used to present an action of object update.
     */
    class Operation: OperationArithmetic {
        /**
         Operation Name.
         */
        enum Name: String {
            case Set            = "Set"
            case Delete         = "Delete"
            case Increment      = "Increment"
            case Add            = "Add"
            case AddUnique      = "AddUnique"
            case AddRelation    = "AddRelation"
            case Remove         = "Remove"
            case RemoveRelation = "RemoveRelation"
        }

        let name: Name
        let key: String
        let value: AnyObject?

        required init(name: Name, key: String, value: AnyObject?) {
            self.name  = name
            self.key   = key
            self.value = value
        }

        /**
         Merge previous operation.

         - parameter operation: Operation to be merged.

         - returns: A new merged operation.
         */
        func merge(previousOperation operation: Operation) -> Operation {
            /* Check every cases to if merge is possible.
             * Permutation can be generated by echo {}{} syntax.
             */
            // switch (operation.name, self.name) {
            // case (.Set, .Set):
            // case (.Set, .Delete):
            // case (.Set, .Increment):
            // case (.Set, .Add):
            // case (.Set, .AddUnique):
            // case (.Set, .AddRelation):
            // case (.Set, .Remove):
            // case (.Set, .RemoveRelation):
            // case (.Delete, .Set):
            // case (.Delete, .Delete):
            // case (.Delete, .Increment):
            // case (.Delete, .Add):
            // case (.Delete, .AddUnique):
            // case (.Delete, .AddRelation):
            // case (.Delete, .Remove):
            // case (.Delete, .RemoveRelation):
            // case (.Increment, .Set):
            // case (.Increment, .Delete):
            // case (.Increment, .Increment):
            // case (.Increment, .Add):
            // case (.Increment, .AddUnique):
            // case (.Increment, .AddRelation):
            // case (.Increment, .Remove):
            // case (.Increment, .RemoveRelation):
            // case (.Add, .Set):
            // case (.Add, .Delete):
            // case (.Add, .Increment):
            // case (.Add, .Add):
            // case (.Add, .AddUnique):
            // case (.Add, .AddRelation):
            // case (.Add, .Remove):
            // case (.Add, .RemoveRelation):
            // case (.AddUnique, .Set):
            // case (.AddUnique, .Delete):
            // case (.AddUnique, .Increment):
            // case (.AddUnique, .Add):
            // case (.AddUnique, .AddUnique):
            // case (.AddUnique, .AddRelation):
            // case (.AddUnique, .Remove):
            // case (.AddUnique, .RemoveRelation):
            // case (.AddRelation, .Set):
            // case (.AddRelation, .Delete):
            // case (.AddRelation, .Increment):
            // case (.AddRelation, .Add):
            // case (.AddRelation, .AddUnique):
            // case (.AddRelation, .AddRelation):
            // case (.AddRelation, .Remove):
            // case (.AddRelation, .RemoveRelation):
            // case (.Remove, .Set):
            // case (.Remove, .Delete):
            // case (.Remove, .Increment):
            // case (.Remove, .Add):
            // case (.Remove, .AddUnique):
            // case (.Remove, .AddRelation):
            // case (.Remove, .Remove):
            // case (.Remove, .RemoveRelation):
            // case (.RemoveRelation, .Set):
            // case (.RemoveRelation, .Delete):
            // case (.RemoveRelation, .Increment):
            // case (.RemoveRelation, .Add):
            // case (.RemoveRelation, .AddUnique):
            // case (.RemoveRelation, .AddRelation):
            // case (.RemoveRelation, .Remove):
            // case (.RemoveRelation, .RemoveRelation):
            // }

            return self
        }

        class Set: Operation {
            /* Stub class */
        }

        class Delete: Operation {
            /* Stub class */
        }

        class Increment: Operation {
            /* Stub class */
        }

        class Add: Operation {
            /* Stub class */
        }

        class AddUnique: Operation {
            /* Stub class */
        }

        class AddRelation: Operation {
            /* Stub class */
        }

        class Remove: Operation {
            /* Stub class */
        }

        class RemoveRelation: Operation {
            /* Stub class */
        }

        static func subclass(operationName name: Operation.Name) -> AnyClass {
            var subclass: AnyClass

            switch name {
            case .Set:            subclass = Operation.Set.self
            case .Delete:         subclass = Operation.Delete.self
            case .Increment:      subclass = Operation.Increment.self
            case .Add:            subclass = Operation.Add.self
            case .AddUnique:      subclass = Operation.AddUnique.self
            case .AddRelation:    subclass = Operation.AddRelation.self
            case .Remove:         subclass = Operation.Remove.self
            case .RemoveRelation: subclass = Operation.RemoveRelation.self
            }

            return subclass
        }
    }

    /**
     Operation hub.

     Used to manage a batch of operations.
     */
    class OperationHub {
        /// A list of all operations.
        lazy var allOperations = [Operation]()

        /// Staged operations.
        /// Used to stage operations to be reduced.
        lazy var stagedOperations = [Operation]()

        /// Untraced operations.
        /// Used to store operations that not ready to be reduced.
        lazy var untracedOperations = [Operation]();

        /**
         Append an operation to hub.

         - parameter name:  Operation name.
         - parameter key:   Key on which to perform.
         - parameter value: Value to be assigned.
         */
        func append(name: Operation.Name, _ key: String, _ value: AnyObject?) {
            let subclass  = Operation.subclass(operationName: name) as! Operation.Type
            let operation = subclass.init(name: name, key: key, value: value)

            untracedOperations.append(operation)
            allOperations.append(operation)
        }

        /**
         Stage untraced operations.
         */
        func stageOperations() {
            stagedOperations.appendContentsOf(untracedOperations)
            untracedOperations.removeAll()
        }

        /**
         Clear all reduced operations.
         */
        func clearReducedOperations() {
            stagedOperations.removeAll()
        }

        /**
         Reduce operations to produce a non-redundant representation.

         - returns: a non-redundant representation of operations.
         */
        func reduce() -> [String:Operation] {
            stageOperations()
            return OperationReducer(operations: stagedOperations).reduce()
        }

        /**
         Produce a payload dictionary for request.

         - returns: A payload dictionary.
         */
        func payload() -> NSDictionary {
            return [:]
        }
    }

    /**
     Operation reducer.

     Used to reduce a batch of operations to avoid redundance and invalid operations.
     */
    private class OperationReducer {
        let operations: [Operation]

        /// A table of non-redundant operations indexed by operation key.
        lazy var operationTable: [String:Operation] = [:]

        init(operations: [Operation]) {
            self.operations = operations
        }

        /**
         Reduce an operation.

         - parameter operation: Operation to be reduced.
         */
        func reduceOperation(var operation: Operation) {
            /* Merge with previous operation which has the same key. */
            if let previousOperation = operationTable[operation.key] {
                operation = operation.merge(previousOperation: previousOperation)
            }

            /* Stub method */
        }

        /**
         Reduce operations to produce a non-redundant representation.

         - returns: a table of reduced operations.
         */
        func reduce() -> [String:Operation] {
            operations.forEach { reduceOperation($0) }
            return operationTable
        }
    }
}