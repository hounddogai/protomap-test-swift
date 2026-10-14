import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves goal targets through their life cycle and keeps a journal of what it did.
    final class GoalTargetCoordinator {
        var store: any GoalTargetStore
        var validator: GoalTargetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GoalTargetEngine

        init(store: any GoalTargetStore, validator: GoalTargetValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GoalTargetEngine) {
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
                throw Kit.Failure("goal target \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GoalTargetStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("goal target \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GoalTargetStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("goal target \(code) not found")
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
                if item.createdAt > cutoff {
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

    static func newGoalTargetCoordinator(_ store: any GoalTargetStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> GoalTargetCoordinator {
        return GoalTargetCoordinator(
            store: store,
            validator: defaultGoalTargetValidator(),
            clock: clock,
            journal: [],
            engine: defaultGoalTargetEngine(flags)
        )
    }
}
