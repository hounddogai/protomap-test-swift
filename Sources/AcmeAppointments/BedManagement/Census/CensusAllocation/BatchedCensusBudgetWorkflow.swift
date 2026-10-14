import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves batched census budgets through their life cycle and keeps a journal of what it did.
    final class BatchedCensusBudgetDesk {
        var store: any BatchedCensusBudgetStore
        var validator: BatchedCensusBudgetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BatchedCensusBudgetEngine

        init(store: any BatchedCensusBudgetStore, validator: BatchedCensusBudgetValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BatchedCensusBudgetEngine) {
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
                throw Kit.Failure("batched census budget \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedCensusBudgetStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched census budget \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedCensusBudgetStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched census budget \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newBatchedCensusBudgetDesk(_ store: any BatchedCensusBudgetStore, clock: any Kit.Clocks.Clock) -> BatchedCensusBudgetDesk {
        return BatchedCensusBudgetDesk(
            store: store,
            validator: defaultBatchedCensusBudgetValidator(),
            clock: clock,
            journal: [],
            engine: defaultBatchedCensusBudgetEngine()
        )
    }
}
