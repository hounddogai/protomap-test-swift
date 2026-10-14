import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves remittance budgets through their life cycle and keeps a journal of what it did.
    final class RemittanceBudgetWorkflow {
        var store: any RemittanceBudgetStore
        var validator: RemittanceBudgetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RemittanceBudgetEngine

        init(store: any RemittanceBudgetStore, validator: RemittanceBudgetValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RemittanceBudgetEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("remittance budget \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RemittanceBudgetStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("remittance budget \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RemittanceBudgetStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("remittance budget \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newRemittanceBudgetWorkflow(_ store: any RemittanceBudgetStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RemittanceBudgetWorkflow {
        return RemittanceBudgetWorkflow(
            store: store,
            validator: defaultRemittanceBudgetValidator(),
            clock: clock,
            journal: [],
            engine: defaultRemittanceBudgetEngine(flags)
        )
    }
}
