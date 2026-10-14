import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves batched interaction budgets through their life cycle and keeps a journal of what it did.
    final class BatchedInteractionBudgetCoordinator {
        var store: any BatchedInteractionBudgetStore
        var validator: BatchedInteractionBudgetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any BatchedInteractionBudgetStore, validator: BatchedInteractionBudgetValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched interaction budget \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedInteractionBudgetStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched interaction budget \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedInteractionBudgetStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
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

    static func newBatchedInteractionBudgetCoordinator(_ store: any BatchedInteractionBudgetStore, clock: any Kit.Clocks.Clock) -> BatchedInteractionBudgetCoordinator {
        return BatchedInteractionBudgetCoordinator(
            store: store,
            validator: defaultBatchedInteractionBudgetValidator(),
            clock: clock,
            journal: []
        )
    }
}
