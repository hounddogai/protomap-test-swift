import AcmePlatform
import Foundation

extension Staffing {
    /// Moves skill mix forecasts through their life cycle and keeps a journal of what it did.
    final class SkillMixForecastDesk {
        var store: any SkillMixForecastStore
        var validator: SkillMixForecastValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any SkillMixForecastStore, validator: SkillMixForecastValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("skill mix forecast \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SkillMixForecastStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("skill mix forecast \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SkillMixForecastStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
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

    static func newSkillMixForecastDesk(_ store: any SkillMixForecastStore, clock: any Kit.Clocks.Clock) -> SkillMixForecastDesk {
        return SkillMixForecastDesk(
            store: store,
            validator: defaultSkillMixForecastValidator(),
            clock: clock,
            journal: []
        )
    }
}
