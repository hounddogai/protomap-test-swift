import AcmePlatform
import Foundation

extension Staffing {
    /// Moves shift budgets through their life cycle and keeps a journal of what it did.
    final class ShiftBudgetDesk {
        var store: any ShiftBudgetStore
        var validator: ShiftBudgetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ShiftBudgetStore, validator: ShiftBudgetValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("shift budget \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ShiftBudgetStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("shift budget \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ShiftBudgetStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newShiftBudgetDesk(_ store: any ShiftBudgetStore, clock: any Kit.Clocks.Clock) -> ShiftBudgetDesk {
        return ShiftBudgetDesk(store: store, validator: defaultShiftBudgetValidator(), clock: clock, journal: [])
    }
}
