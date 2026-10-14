import AcmePlatform
import Foundation

extension Staffing {
    /// Moves credential rules through their life cycle and keeps a journal of what it did.
    final class CredentialRuleManager {
        var store: any CredentialRuleStore
        var validator: CredentialRuleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CredentialRuleEngine

        init(store: any CredentialRuleStore, validator: CredentialRuleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CredentialRuleEngine) {
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
                throw Kit.Failure("credential rule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CredentialRuleStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("credential rule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CredentialRuleStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("credential rule \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newCredentialRuleManager(_ store: any CredentialRuleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CredentialRuleManager {
        return CredentialRuleManager(
            store: store,
            validator: defaultCredentialRuleValidator(),
            clock: clock,
            journal: [],
            engine: defaultCredentialRuleEngine(flags)
        )
    }
}
