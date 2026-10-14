import AcmePlatform
import Foundation

extension Labs {
    /// Moves capped panel budgets through their life cycle and keeps a journal of what it did.
    final class CappedPanelBudgetWorkflow {
        var store: any CappedPanelBudgetStore
        var validator: CappedPanelBudgetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CappedPanelBudgetEngine

        init(store: any CappedPanelBudgetStore, validator: CappedPanelBudgetValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CappedPanelBudgetEngine) {
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
                throw Kit.Failure("capped panel budget \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedPanelBudgetStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped panel budget \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedPanelBudgetStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped panel budget \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newCappedPanelBudgetWorkflow(_ store: any CappedPanelBudgetStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CappedPanelBudgetWorkflow {
        return CappedPanelBudgetWorkflow(
            store: store,
            validator: defaultCappedPanelBudgetValidator(),
            clock: clock,
            journal: [],
            engine: defaultCappedPanelBudgetEngine(flags)
        )
    }
}
