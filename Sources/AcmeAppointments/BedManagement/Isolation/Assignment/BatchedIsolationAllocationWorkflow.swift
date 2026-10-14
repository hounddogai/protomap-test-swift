import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves batched isolation allocations through their life cycle and keeps a journal of what it did.
    final class BatchedIsolationAllocationService {
        var store: any BatchedIsolationAllocationStore
        var validator: BatchedIsolationAllocationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BatchedIsolationAllocationEngine

        init(store: any BatchedIsolationAllocationStore, validator: BatchedIsolationAllocationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BatchedIsolationAllocationEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched isolation allocation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedIsolationAllocationStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched isolation allocation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedIsolationAllocationStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched isolation allocation \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
                    continue
                }
                let problems = validator.validate(item)
                if problems.count == 0 {
                    continue
                }
                self.note("\(item.code) needs attention: \(problems.joined(separator: ", "))")
                changed += 1
            }
            return changed
        }
    }

    static func newBatchedIsolationAllocationService(_ store: any BatchedIsolationAllocationStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> BatchedIsolationAllocationService {
        return BatchedIsolationAllocationService(
            store: store,
            validator: defaultBatchedIsolationAllocationValidator(),
            clock: clock,
            journal: [],
            engine: defaultBatchedIsolationAllocationEngine(flags)
        )
    }
}
