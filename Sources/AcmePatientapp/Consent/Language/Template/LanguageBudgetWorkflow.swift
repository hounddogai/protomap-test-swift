import AcmePlatform
import Foundation

extension Consent {
    /// Moves language budgets through their life cycle and keeps a journal of what it did.
    final class LanguageBudgetDesk {
        var store: any LanguageBudgetStore
        var validator: LanguageBudgetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LanguageBudgetEngine

        init(store: any LanguageBudgetStore, validator: LanguageBudgetValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LanguageBudgetEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("language budget \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LanguageBudgetStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("language budget \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LanguageBudgetStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("language budget \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newLanguageBudgetDesk(_ store: any LanguageBudgetStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> LanguageBudgetDesk {
        return LanguageBudgetDesk(
            store: store,
            validator: defaultLanguageBudgetValidator(),
            clock: clock,
            journal: [],
            engine: defaultLanguageBudgetEngine(flags)
        )
    }
}
