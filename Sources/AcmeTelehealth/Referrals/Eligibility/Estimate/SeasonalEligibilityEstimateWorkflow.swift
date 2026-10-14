import AcmePlatform
import Foundation

extension Referrals {
    /// Moves seasonal eligibility estimates through their life cycle and keeps a journal of what it did.
    final class SeasonalEligibilityEstimateManager {
        var store: any SeasonalEligibilityEstimateStore
        var validator: SeasonalEligibilityEstimateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SeasonalEligibilityEstimateEngine

        init(store: any SeasonalEligibilityEstimateStore, validator: SeasonalEligibilityEstimateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SeasonalEligibilityEstimateEngine) {
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
                throw Kit.Failure("seasonal eligibility estimate \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalEligibilityEstimateStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal eligibility estimate \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalEligibilityEstimateStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal eligibility estimate \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newSeasonalEligibilityEstimateManager(_ store: any SeasonalEligibilityEstimateStore, clock: any Kit.Clocks.Clock) -> SeasonalEligibilityEstimateManager {
        return SeasonalEligibilityEstimateManager(
            store: store,
            validator: defaultSeasonalEligibilityEstimateValidator(),
            clock: clock,
            journal: [],
            engine: defaultSeasonalEligibilityEstimateEngine()
        )
    }
}
