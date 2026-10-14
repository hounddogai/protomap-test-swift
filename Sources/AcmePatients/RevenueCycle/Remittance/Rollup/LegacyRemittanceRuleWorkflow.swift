import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves legacy remittance rules through their life cycle and keeps a journal of what it did.
    final class LegacyRemittanceRuleDesk {
        var store: any LegacyRemittanceRuleStore
        var validator: LegacyRemittanceRuleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LegacyRemittanceRuleEngine

        init(store: any LegacyRemittanceRuleStore, validator: LegacyRemittanceRuleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LegacyRemittanceRuleEngine) {
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
                throw Kit.Failure("legacy remittance rule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyRemittanceRuleStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy remittance rule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyRemittanceRuleStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy remittance rule \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
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

    static func newLegacyRemittanceRuleDesk(_ store: any LegacyRemittanceRuleStore, clock: any Kit.Clocks.Clock) -> LegacyRemittanceRuleDesk {
        return LegacyRemittanceRuleDesk(
            store: store,
            validator: defaultLegacyRemittanceRuleValidator(),
            clock: clock,
            journal: [],
            engine: defaultLegacyRemittanceRuleEngine()
        )
    }
}
