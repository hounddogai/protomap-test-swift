import AcmePlatform
import Foundation

extension Labs {
    /// Moves batched specimen budgets through their life cycle and keeps a journal of what it did.
    final class BatchedSpecimenBudgetDesk {
        var store: any BatchedSpecimenBudgetStore
        var validator: BatchedSpecimenBudgetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any BatchedSpecimenBudgetStore, validator: BatchedSpecimenBudgetValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched specimen budget \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedSpecimenBudgetStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched specimen budget \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedSpecimenBudgetStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
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

    static func newBatchedSpecimenBudgetDesk(_ store: any BatchedSpecimenBudgetStore, clock: any Kit.Clocks.Clock) -> BatchedSpecimenBudgetDesk {
        return BatchedSpecimenBudgetDesk(
            store: store,
            validator: defaultBatchedSpecimenBudgetValidator(),
            clock: clock,
            journal: []
        )
    }
}
