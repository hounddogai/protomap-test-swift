import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves batched claim targets through their life cycle and keeps a journal of what it did.
    final class BatchedClaimTargetDesk {
        var store: any BatchedClaimTargetStore
        var validator: BatchedClaimTargetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BatchedClaimTargetEngine

        init(store: any BatchedClaimTargetStore, validator: BatchedClaimTargetValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BatchedClaimTargetEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched claim target \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedClaimTargetStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched claim target \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedClaimTargetStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched claim target \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
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

    static func newBatchedClaimTargetDesk(_ store: any BatchedClaimTargetStore, clock: any Kit.Clocks.Clock) -> BatchedClaimTargetDesk {
        return BatchedClaimTargetDesk(
            store: store,
            validator: defaultBatchedClaimTargetValidator(),
            clock: clock,
            journal: [],
            engine: defaultBatchedClaimTargetEngine()
        )
    }
}
