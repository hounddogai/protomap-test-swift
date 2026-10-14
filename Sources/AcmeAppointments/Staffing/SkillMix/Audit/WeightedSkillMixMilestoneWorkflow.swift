import AcmePlatform
import Foundation

extension Staffing {
    /// Moves weighted skill mix milestones through their life cycle and keeps a journal of what it did.
    final class WeightedSkillMixMilestoneCoordinator {
        var store: any WeightedSkillMixMilestoneStore
        var validator: WeightedSkillMixMilestoneValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WeightedSkillMixMilestoneEngine

        init(store: any WeightedSkillMixMilestoneStore, validator: WeightedSkillMixMilestoneValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WeightedSkillMixMilestoneEngine) {
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
                throw Kit.Failure("weighted skill mix milestone \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedSkillMixMilestoneStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted skill mix milestone \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedSkillMixMilestoneStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted skill mix milestone \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newWeightedSkillMixMilestoneCoordinator(_ store: any WeightedSkillMixMilestoneStore, clock: any Kit.Clocks.Clock) -> WeightedSkillMixMilestoneCoordinator {
        return WeightedSkillMixMilestoneCoordinator(
            store: store,
            validator: defaultWeightedSkillMixMilestoneValidator(),
            clock: clock,
            journal: [],
            engine: defaultWeightedSkillMixMilestoneEngine()
        )
    }
}
