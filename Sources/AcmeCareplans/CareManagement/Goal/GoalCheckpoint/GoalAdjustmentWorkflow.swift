import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves goal adjustments through their life cycle and keeps a journal of what it did.
    final class GoalAdjustmentCoordinator {
        var store: any GoalAdjustmentStore
        var validator: GoalAdjustmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GoalAdjustmentEngine

        init(store: any GoalAdjustmentStore, validator: GoalAdjustmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GoalAdjustmentEngine) {
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
                throw Kit.Failure("goal adjustment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GoalAdjustmentStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("goal adjustment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GoalAdjustmentStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("goal adjustment \(code) not found")
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

    static func newGoalAdjustmentCoordinator(_ store: any GoalAdjustmentStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> GoalAdjustmentCoordinator {
        return GoalAdjustmentCoordinator(
            store: store,
            validator: defaultGoalAdjustmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultGoalAdjustmentEngine(flags)
        )
    }
}
