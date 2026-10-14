import AcmePlatform
import Foundation

extension Staffing {
    /// Moves strict skill mix forecasts through their life cycle and keeps a journal of what it did.
    final class StrictSkillMixForecastManager {
        var store: any StrictSkillMixForecastStore
        var validator: StrictSkillMixForecastValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: StrictSkillMixForecastEngine

        init(store: any StrictSkillMixForecastStore, validator: StrictSkillMixForecastValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: StrictSkillMixForecastEngine) {
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
                throw Kit.Failure("strict skill mix forecast \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictSkillMixForecastStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict skill mix forecast \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictSkillMixForecastStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict skill mix forecast \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newStrictSkillMixForecastManager(_ store: any StrictSkillMixForecastStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> StrictSkillMixForecastManager {
        return StrictSkillMixForecastManager(
            store: store,
            validator: defaultStrictSkillMixForecastValidator(),
            clock: clock,
            journal: [],
            engine: defaultStrictSkillMixForecastEngine(flags)
        )
    }
}
