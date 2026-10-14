import AcmePlatform
import Foundation

extension Staffing {
    /// Moves skill mix plans through their life cycle and keeps a journal of what it did.
    final class SkillMixPlanManager {
        var store: any SkillMixPlanStore
        var validator: SkillMixPlanValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SkillMixPlanEngine

        init(store: any SkillMixPlanStore, validator: SkillMixPlanValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SkillMixPlanEngine) {
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
                throw Kit.Failure("skill mix plan \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SkillMixPlanStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("skill mix plan \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SkillMixPlanStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("skill mix plan \(code) not found")
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

    static func newSkillMixPlanManager(_ store: any SkillMixPlanStore, clock: any Kit.Clocks.Clock) -> SkillMixPlanManager {
        return SkillMixPlanManager(
            store: store,
            validator: defaultSkillMixPlanValidator(),
            clock: clock,
            journal: [],
            engine: defaultSkillMixPlanEngine()
        )
    }
}
