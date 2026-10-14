import AcmePlatform
import Foundation

extension Referrals {
    /// Moves legacy eligibility baselines through their life cycle and keeps a journal of what it did.
    final class LegacyEligibilityBaselineCoordinator {
        var store: any LegacyEligibilityBaselineStore
        var validator: LegacyEligibilityBaselineValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LegacyEligibilityBaselineEngine

        init(store: any LegacyEligibilityBaselineStore, validator: LegacyEligibilityBaselineValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LegacyEligibilityBaselineEngine) {
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
                throw Kit.Failure("legacy eligibility baseline \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyEligibilityBaselineStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy eligibility baseline \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyEligibilityBaselineStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy eligibility baseline \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newLegacyEligibilityBaselineCoordinator(_ store: any LegacyEligibilityBaselineStore, clock: any Kit.Clocks.Clock) -> LegacyEligibilityBaselineCoordinator {
        return LegacyEligibilityBaselineCoordinator(
            store: store,
            validator: defaultLegacyEligibilityBaselineValidator(),
            clock: clock,
            journal: [],
            engine: defaultLegacyEligibilityBaselineEngine()
        )
    }
}
