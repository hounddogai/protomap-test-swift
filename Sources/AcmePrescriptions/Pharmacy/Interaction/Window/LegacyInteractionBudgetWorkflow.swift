import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves legacy interaction budgets through their life cycle and keeps a journal of what it did.
    final class LegacyInteractionBudgetDesk {
        var store: any LegacyInteractionBudgetStore
        var validator: LegacyInteractionBudgetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any LegacyInteractionBudgetStore, validator: LegacyInteractionBudgetValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("legacy interaction budget \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyInteractionBudgetStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy interaction budget \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyInteractionBudgetStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
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

    static func newLegacyInteractionBudgetDesk(_ store: any LegacyInteractionBudgetStore, clock: any Kit.Clocks.Clock) -> LegacyInteractionBudgetDesk {
        return LegacyInteractionBudgetDesk(
            store: store,
            validator: defaultLegacyInteractionBudgetValidator(),
            clock: clock,
            journal: []
        )
    }
}
