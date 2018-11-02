/* Copyright 2018 Miquido
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License. */

import Dispatch

/// Worker wrapper for DispatchQueue
public enum DispatchWorker {
    case main
    case `default`
    case utility
    case background
    case custom(DispatchQueue)
}

extension DispatchWorker : Worker {
    
    /// Assigns given work at the end of queue.
    /// Depending on queue type (serial or concurrent) behaviour may be different.
    /// It simple calls DispatchQueue.async for task execution.
    public func schedule(_ work: @escaping () -> Void) -> Void {
        queue.async(execute: work)
    }
}

fileprivate extension DispatchWorker {
    
    var queue: DispatchQueue {
        switch self {
        case .main:
            return .main
        case .default:
            return .global(qos: .default)
        case .utility:
            return .global(qos: .utility)
        case .background:
            return .global(qos: .background)
        case let .custom(customQueue):
            return customQueue
        }
    }
}