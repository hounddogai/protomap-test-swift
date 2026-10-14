import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves batched remittance targets through their life cycle and keeps a journal of what it did.
    final class BatchedRemittanceTargetService {
        var store: any BatchedRemittanceTargetStore
        var validator: BatchedRemittanceTargetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BatchedRemittanceTargetEngine

        init(store: any BatchedRemittanceTargetStore, validator: BatchedRemittanceTargetValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BatchedRemittanceTargetEngine) {
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
                throw Kit.Failure("batched remittance target \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedRemittanceTargetStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched remittance target \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedRemittanceTargetStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched remittance target \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newBatchedRemittanceTargetService(_ store: any BatchedRemittanceTargetStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> BatchedRemittanceTargetService {
        return BatchedRemittanceTargetService(
            store: store,
            validator: defaultBatchedRemittanceTargetValidator(),
            clock: clock,
            journal: [],
            engine: defaultBatchedRemittanceTargetEngine(flags)
        )
    }
}
