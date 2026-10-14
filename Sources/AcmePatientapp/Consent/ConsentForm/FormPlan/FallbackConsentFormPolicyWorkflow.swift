import AcmePlatform
import Foundation

extension Consent {
    /// Moves fallback consent form policies through their life cycle and keeps a journal of what it did.
    final class FallbackConsentFormPolicyWorkflow {
        var store: any FallbackConsentFormPolicyStore
        var validator: FallbackConsentFormPolicyValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FallbackConsentFormPolicyEngine

        init(store: any FallbackConsentFormPolicyStore, validator: FallbackConsentFormPolicyValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FallbackConsentFormPolicyEngine) {
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
                throw Kit.Failure("fallback consent form policy \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackConsentFormPolicyStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback consent form policy \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackConsentFormPolicyStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback consent form policy \(code) not found")
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

    static func newFallbackConsentFormPolicyWorkflow(_ store: any FallbackConsentFormPolicyStore, clock: any Kit.Clocks.Clock) -> FallbackConsentFormPolicyWorkflow {
        return FallbackConsentFormPolicyWorkflow(
            store: store,
            validator: defaultFallbackConsentFormPolicyValidator(),
            clock: clock,
            journal: [],
            engine: defaultFallbackConsentFormPolicyEngine()
        )
    }
}
