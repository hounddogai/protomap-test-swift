import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves dispense budgets through their life cycle and keeps a journal of what it did.
    final class DispenseBudgetWorkflow {
        var store: any DispenseBudgetStore
        var validator: DispenseBudgetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any DispenseBudgetStore, validator: DispenseBudgetValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("dispense budget \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DispenseBudgetStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("dispense budget \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DispenseBudgetStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
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

    static func newDispenseBudgetWorkflow(_ store: any DispenseBudgetStore, clock: any Kit.Clocks.Clock) -> DispenseBudgetWorkflow {
        return DispenseBudgetWorkflow(
            store: store,
            validator: defaultDispenseBudgetValidator(),
            clock: clock,
            journal: []
        )
    }
}
