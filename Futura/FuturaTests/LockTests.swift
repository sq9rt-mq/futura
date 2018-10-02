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

import XCTest
import Futura

class LockTests: XCTestCase {
    
    func testShould_NotCrash_When_ReleasingLocked() {
        Lock().lock()
    }
    
    func testShould_LockAndUnlock_When_CalledOnDistinctThreads() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let lock = Lock()
            var completed: Bool = false
            
            lock.lock()
            DispatchWorker.default.schedule {
                lock.lock()
                XCTAssert(completed, "Lock unlocked while should be locked")
                complete()
            }
            sleep(1)
            completed = true
            lock.unlock()
        }
    }
    
    func testShould_LockAndUnlock_When_CalledOnSameThread() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let lock = Lock()
            
            lock.lock()
            lock.lock()
            lock.lock()
            lock.unlock()
            lock.unlock()
            lock.unlock()
            
            complete()
        }
    }
    
    func testShould_SucceedTryLock_When_Unlocked() {
        let lock = Lock()
        
        guard lock.tryLock() else {
            return XCTFail("Lock failed to lock")
        }
    }
    
    func testShould_SucceedTryLock_When_LockedOnSameThread() {
        let lock = Lock()
        lock.lock()
        
        guard lock.tryLock() else {
            return XCTFail("Lock failed to lock")
        }
    }
    
    func testShould_FailTryLock_When_LockedOnOtherThread() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let lock = Lock()
            lock.lock()
            
            DispatchWorker.default.schedule {
                defer { complete() }
                guard !lock.tryLock() else {
                    return XCTFail("Lock not failed to lock")
                }
            }
            sleep(1) // ensure that will not exit too early deallocating lock
        }
    }
    
    func testShould_SynchronizeBlock_When_CalledOnDistinctThreads() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let lock = Lock()
            var testValue = 0
            
            DispatchWorker.default.schedule {
                lock.synchronized {
                    sleep(2) // ensure that claims lock longer
                    XCTAssert(testValue == 0, "Test value changed without synchronization")
                    testValue += 1
                }
            }
            sleep(1) // ensure that DispatchWorker performs its task before
            lock.synchronized {
                XCTAssert(testValue == 1, "Test value changed without synchronization")
            }
            
            complete()
        }
    }
    
    func testShould_NotCauseDeadlock_When_SynchronizedCalledRecursively() {
        asyncTest(iterationTimeout: 6,
                  timeoutBody: {
                    XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let lock = Lock()
            var completed: Bool = false
            
            lock.synchronized {
                lock.synchronized {
                    lock.synchronized {
                        lock.synchronized {
                            lock.synchronized {
                                completed = true
                            }
                        }
                    }
                }
            }
            
            XCTAssert(completed, "Synchronized blocks not performed")
            complete()
        }
    }
    
    func testShould_ThrowInSynchronizedWithoutChangingError() {
        let lock = Lock()
        let expectedResult = TestError()
        
        do {
            try lock.synchronized { throw expectedResult }
            XCTFail("Lock not threw")
        } catch {
            XCTAssert(error is TestError, "Catched error does not match expected. Expected: \(expectedResult) Recieved: \(error)")
        }
    }
    
    func testPerformance_LockAndUnlock() {
        measure {
            let lock = Lock()
            var total = 0
            
            for _ in 0..<performanceTestIterations {
                lock.lock()
                total += 1
                lock.unlock()
            }
            
            XCTAssert(total == performanceTestIterations)
        }
    }
}
