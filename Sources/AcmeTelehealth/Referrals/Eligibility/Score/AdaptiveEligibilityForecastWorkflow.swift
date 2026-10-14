import AcmePlatform
import Foundation

extension Referrals {
    /// Moves adaptive eligibility forecasts through their life cycle and keeps a journal of what it did.
    final class AdaptiveEligibilityForecastWorkflow {
        var store: any AdaptiveEligibilityForecastStore
        var validator: AdaptiveEligibilityForecastValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any AdaptiveEligibilityForecastStore, validator: AdaptiveEligibilityForecastValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive eligibility forecast \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptiveEligibilityForecastStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive eligibility forecast \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptiveEligibilityForecastStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newAdaptiveEligibilityForecastWorkflow(_ store: any AdaptiveEligibilityForecastStore, clock: any Kit.Clocks.Clock) -> AdaptiveEligibilityForecastWorkflow {
        return AdaptiveEligibilityForecastWorkflow(
            store: store,
            validator: defaultAdaptiveEligibilityForecastValidator(),
            clock: clock,
            journal: []
        )
    }
}
