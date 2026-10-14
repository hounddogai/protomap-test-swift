import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves goal allocations through their life cycle and keeps a journal of what it did.
    final class GoalAllocationManager {
        var store: any GoalAllocationStore
        var validator: GoalAllocationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GoalAllocationEngine

        init(store: any GoalAllocationStore, validator: GoalAllocationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GoalAllocationEngine) {
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
                throw Kit.Failure("goal allocation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GoalAllocationStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("goal allocation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GoalAllocationStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("goal allocation \(code) not found")
            }
            let result = engine.price(item)
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

    static func newGoalAllocationManager(_ store: any GoalAllocationStore, clock: any Kit.Clocks.Clock) -> GoalAllocationManager {
        return GoalAllocationManager(
            store: store,
            validator: defaultGoalAllocationValidator(),
            clock: clock,
            journal: [],
            engine: defaultGoalAllocationEngine()
        )
    }
}
