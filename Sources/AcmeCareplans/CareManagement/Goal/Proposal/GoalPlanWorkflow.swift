import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves goal plans through their life cycle and keeps a journal of what it did.
    final class GoalPlanDesk {
        var store: any GoalPlanStore
        var validator: GoalPlanValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GoalPlanEngine

        init(store: any GoalPlanStore, validator: GoalPlanValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GoalPlanEngine) {
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
                throw Kit.Failure("goal plan \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GoalPlanStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("goal plan \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GoalPlanStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("goal plan \(code) not found")
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

    static func newGoalPlanDesk(_ store: any GoalPlanStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> GoalPlanDesk {
        return GoalPlanDesk(
            store: store,
            validator: defaultGoalPlanValidator(),
            clock: clock,
            journal: [],
            engine: defaultGoalPlanEngine(flags)
        )
    }
}
