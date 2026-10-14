import AcmePlatform
import Foundation

extension Consent {
    /// Moves capped consent form rules through their life cycle and keeps a journal of what it did.
    final class CappedConsentFormRuleCoordinator {
        var store: any CappedConsentFormRuleStore
        var validator: CappedConsentFormRuleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CappedConsentFormRuleEngine

        init(store: any CappedConsentFormRuleStore, validator: CappedConsentFormRuleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CappedConsentFormRuleEngine) {
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
                throw Kit.Failure("capped consent form rule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedConsentFormRuleStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped consent form rule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedConsentFormRuleStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped consent form rule \(code) not found")
            }
            let result = engine.price(item)
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

    static func newCappedConsentFormRuleCoordinator(_ store: any CappedConsentFormRuleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CappedConsentFormRuleCoordinator {
        return CappedConsentFormRuleCoordinator(
            store: store,
            validator: defaultCappedConsentFormRuleValidator(),
            clock: clock,
            journal: [],
            engine: defaultCappedConsentFormRuleEngine(flags)
        )
    }
}
