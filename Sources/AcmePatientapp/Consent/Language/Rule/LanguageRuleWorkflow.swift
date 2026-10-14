import AcmePlatform
import Foundation

extension Consent {
    /// Moves language rules through their life cycle and keeps a journal of what it did.
    final class LanguageRuleWorkflow {
        var store: any LanguageRuleStore
        var validator: LanguageRuleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LanguageRuleEngine

        init(store: any LanguageRuleStore, validator: LanguageRuleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LanguageRuleEngine) {
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
                throw Kit.Failure("language rule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LanguageRuleStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("language rule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LanguageRuleStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("language rule \(code) not found")
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

    static func newLanguageRuleWorkflow(_ store: any LanguageRuleStore, clock: any Kit.Clocks.Clock) -> LanguageRuleWorkflow {
        return LanguageRuleWorkflow(
            store: store,
            validator: defaultLanguageRuleValidator(),
            clock: clock,
            journal: [],
            engine: defaultLanguageRuleEngine()
        )
    }
}
