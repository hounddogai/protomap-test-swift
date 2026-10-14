import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves task budgets through their life cycle and keeps a journal of what it did.
    final class TaskBudgetCoordinator {
        var store: any TaskBudgetStore
        var validator: TaskBudgetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any TaskBudgetStore, validator: TaskBudgetValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("task budget \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TaskBudgetStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("task budget \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TaskBudgetStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newTaskBudgetCoordinator(_ store: any TaskBudgetStore, clock: any Kit.Clocks.Clock) -> TaskBudgetCoordinator {
        return TaskBudgetCoordinator(
            store: store,
            validator: defaultTaskBudgetValidator(),
            clock: clock,
            journal: []
        )
    }
}
