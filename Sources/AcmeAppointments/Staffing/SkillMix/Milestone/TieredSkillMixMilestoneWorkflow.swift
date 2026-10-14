import AcmePlatform
import Foundation

extension Staffing {
    /// Moves tiered skill mix milestones through their life cycle and keeps a journal of what it did.
    final class TieredSkillMixMilestoneManager {
        var store: any TieredSkillMixMilestoneStore
        var validator: TieredSkillMixMilestoneValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TieredSkillMixMilestoneEngine

        init(store: any TieredSkillMixMilestoneStore, validator: TieredSkillMixMilestoneValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TieredSkillMixMilestoneEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered skill mix milestone \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredSkillMixMilestoneStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered skill mix milestone \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredSkillMixMilestoneStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered skill mix milestone \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newTieredSkillMixMilestoneManager(_ store: any TieredSkillMixMilestoneStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> TieredSkillMixMilestoneManager {
        return TieredSkillMixMilestoneManager(
            store: store,
            validator: defaultTieredSkillMixMilestoneValidator(),
            clock: clock,
            journal: [],
            engine: defaultTieredSkillMixMilestoneEngine(flags)
        )
    }
}
