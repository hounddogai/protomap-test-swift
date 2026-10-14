import AcmePlatform
import Foundation

extension Staffing {
    /// Moves skill mix metrics through their life cycle and keeps a journal of what it did.
    final class SkillMixMetricCoordinator {
        var store: any SkillMixMetricStore
        var validator: SkillMixMetricValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SkillMixMetricEngine

        init(store: any SkillMixMetricStore, validator: SkillMixMetricValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SkillMixMetricEngine) {
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
                throw Kit.Failure("skill mix metric \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SkillMixMetricStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("skill mix metric \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SkillMixMetricStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("skill mix metric \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newSkillMixMetricCoordinator(_ store: any SkillMixMetricStore, clock: any Kit.Clocks.Clock) -> SkillMixMetricCoordinator {
        return SkillMixMetricCoordinator(
            store: store,
            validator: defaultSkillMixMetricValidator(),
            clock: clock,
            journal: [],
            engine: defaultSkillMixMetricEngine()
        )
    }
}
