import AcmePlatform
import Foundation

extension Consent {
    /// Moves revocation rules through their life cycle and keeps a journal of what it did.
    final class RevocationRuleWorkflow {
        var store: any RevocationRuleStore
        var validator: RevocationRuleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RevocationRuleEngine

        init(store: any RevocationRuleStore, validator: RevocationRuleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RevocationRuleEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("revocation rule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RevocationRuleStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("revocation rule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RevocationRuleStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("revocation rule \(code) not found")
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

    static func newRevocationRuleWorkflow(_ store: any RevocationRuleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RevocationRuleWorkflow {
        return RevocationRuleWorkflow(
            store: store,
            validator: defaultRevocationRuleValidator(),
            clock: clock,
            journal: [],
            engine: defaultRevocationRuleEngine(flags)
        )
    }
}
