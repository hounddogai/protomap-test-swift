import AcmePlatform
import Foundation

extension Consent {
    /// Moves fallback language budgets through their life cycle and keeps a journal of what it did.
    final class FallbackLanguageBudgetWorkflow {
        var store: any FallbackLanguageBudgetStore
        var validator: FallbackLanguageBudgetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FallbackLanguageBudgetEngine

        init(store: any FallbackLanguageBudgetStore, validator: FallbackLanguageBudgetValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FallbackLanguageBudgetEngine) {
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
                throw Kit.Failure("fallback language budget \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackLanguageBudgetStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback language budget \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackLanguageBudgetStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback language budget \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newFallbackLanguageBudgetWorkflow(_ store: any FallbackLanguageBudgetStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> FallbackLanguageBudgetWorkflow {
        return FallbackLanguageBudgetWorkflow(
            store: store,
            validator: defaultFallbackLanguageBudgetValidator(),
            clock: clock,
            journal: [],
            engine: defaultFallbackLanguageBudgetEngine(flags)
        )
    }
}
