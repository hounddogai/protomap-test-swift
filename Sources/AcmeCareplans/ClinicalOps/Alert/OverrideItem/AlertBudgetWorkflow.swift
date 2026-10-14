import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves alert budgets through their life cycle and keeps a journal of what it did.
    final class AlertBudgetService {
        var store: any AlertBudgetStore
        var validator: AlertBudgetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AlertBudgetEngine

        init(store: any AlertBudgetStore, validator: AlertBudgetValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AlertBudgetEngine) {
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
                throw Kit.Failure("alert budget \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AlertBudgetStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("alert budget \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AlertBudgetStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("alert budget \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newAlertBudgetService(_ store: any AlertBudgetStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> AlertBudgetService {
        return AlertBudgetService(
            store: store,
            validator: defaultAlertBudgetValidator(),
            clock: clock,
            journal: [],
            engine: defaultAlertBudgetEngine(flags)
        )
    }
}
