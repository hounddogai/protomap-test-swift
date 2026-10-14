import AcmePlatform
import Foundation

extension Staffing {
    /// Moves seasonal skill mix plans through their life cycle and keeps a journal of what it did.
    final class SeasonalSkillMixPlanDesk {
        var store: any SeasonalSkillMixPlanStore
        var validator: SeasonalSkillMixPlanValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SeasonalSkillMixPlanEngine

        init(store: any SeasonalSkillMixPlanStore, validator: SeasonalSkillMixPlanValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SeasonalSkillMixPlanEngine) {
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
                throw Kit.Failure("seasonal skill mix plan \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalSkillMixPlanStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal skill mix plan \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalSkillMixPlanStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal skill mix plan \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newSeasonalSkillMixPlanDesk(_ store: any SeasonalSkillMixPlanStore, clock: any Kit.Clocks.Clock) -> SeasonalSkillMixPlanDesk {
        return SeasonalSkillMixPlanDesk(
            store: store,
            validator: defaultSeasonalSkillMixPlanValidator(),
            clock: clock,
            journal: [],
            engine: defaultSeasonalSkillMixPlanEngine()
        )
    }
}
