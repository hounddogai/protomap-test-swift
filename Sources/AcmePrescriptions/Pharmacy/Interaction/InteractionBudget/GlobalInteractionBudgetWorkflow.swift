import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves global interaction budgets through their life cycle and keeps a journal of what it did.
    final class GlobalInteractionBudgetDesk {
        var store: any GlobalInteractionBudgetStore
        var validator: GlobalInteractionBudgetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any GlobalInteractionBudgetStore, validator: GlobalInteractionBudgetValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("global interaction budget \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalInteractionBudgetStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global interaction budget \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalInteractionBudgetStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newGlobalInteractionBudgetDesk(_ store: any GlobalInteractionBudgetStore, clock: any Kit.Clocks.Clock) -> GlobalInteractionBudgetDesk {
        return GlobalInteractionBudgetDesk(
            store: store,
            validator: defaultGlobalInteractionBudgetValidator(),
            clock: clock,
            journal: []
        )
    }
}
