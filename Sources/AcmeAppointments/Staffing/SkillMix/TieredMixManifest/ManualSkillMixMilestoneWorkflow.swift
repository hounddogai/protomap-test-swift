import AcmePlatform
import Foundation

extension Staffing {
    /// Moves manual skill mix milestones through their life cycle and keeps a journal of what it did.
    final class ManualSkillMixMilestoneCoordinator {
        var store: any ManualSkillMixMilestoneStore
        var validator: ManualSkillMixMilestoneValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ManualSkillMixMilestoneStore, validator: ManualSkillMixMilestoneValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("manual skill mix milestone \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualSkillMixMilestoneStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual skill mix milestone \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualSkillMixMilestoneStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newManualSkillMixMilestoneCoordinator(_ store: any ManualSkillMixMilestoneStore, clock: any Kit.Clocks.Clock) -> ManualSkillMixMilestoneCoordinator {
        return ManualSkillMixMilestoneCoordinator(
            store: store,
            validator: defaultManualSkillMixMilestoneValidator(),
            clock: clock,
            journal: []
        )
    }
}
