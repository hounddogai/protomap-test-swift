import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves goal budgets through their life cycle and keeps a journal of what it did.
    final class GoalBudgetWorkflow {
        var store: any GoalBudgetStore
        var validator: GoalBudgetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any GoalBudgetStore, validator: GoalBudgetValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("goal budget \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GoalBudgetStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("goal budget \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GoalBudgetStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newGoalBudgetWorkflow(_ store: any GoalBudgetStore, clock: any Kit.Clocks.Clock) -> GoalBudgetWorkflow {
        return GoalBudgetWorkflow(store: store, validator: defaultGoalBudgetValidator(), clock: clock, journal: [])
    }
}
