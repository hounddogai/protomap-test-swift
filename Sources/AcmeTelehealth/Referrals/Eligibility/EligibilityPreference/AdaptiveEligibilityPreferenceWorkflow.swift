import AcmePlatform
import Foundation

extension Referrals {
    /// Moves adaptive eligibility preferences through their life cycle and keeps a journal of what it did.
    final class AdaptiveEligibilityPreferenceDesk {
        var store: any AdaptiveEligibilityPreferenceStore
        var validator: AdaptiveEligibilityPreferenceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AdaptiveEligibilityPreferenceEngine

        init(store: any AdaptiveEligibilityPreferenceStore, validator: AdaptiveEligibilityPreferenceValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AdaptiveEligibilityPreferenceEngine) {
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
                throw Kit.Failure("adaptive eligibility preference \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptiveEligibilityPreferenceStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive eligibility preference \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptiveEligibilityPreferenceStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive eligibility preference \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newAdaptiveEligibilityPreferenceDesk(_ store: any AdaptiveEligibilityPreferenceStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> AdaptiveEligibilityPreferenceDesk {
        return AdaptiveEligibilityPreferenceDesk(
            store: store,
            validator: defaultAdaptiveEligibilityPreferenceValidator(),
            clock: clock,
            journal: [],
            engine: defaultAdaptiveEligibilityPreferenceEngine(flags)
        )
    }
}
