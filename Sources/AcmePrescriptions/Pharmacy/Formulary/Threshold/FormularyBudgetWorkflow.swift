import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves formulary budgets through their life cycle and keeps a journal of what it did.
    final class FormularyBudgetCoordinator {
        var store: any FormularyBudgetStore
        var validator: FormularyBudgetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FormularyBudgetEngine

        init(store: any FormularyBudgetStore, validator: FormularyBudgetValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FormularyBudgetEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("formulary budget \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FormularyBudgetStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("formulary budget \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FormularyBudgetStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("formulary budget \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newFormularyBudgetCoordinator(_ store: any FormularyBudgetStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> FormularyBudgetCoordinator {
        return FormularyBudgetCoordinator(
            store: store,
            validator: defaultFormularyBudgetValidator(),
            clock: clock,
            journal: [],
            engine: defaultFormularyBudgetEngine(flags)
        )
    }
}
