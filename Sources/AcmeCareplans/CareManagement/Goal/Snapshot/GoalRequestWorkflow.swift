import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves goal requests through their life cycle and keeps a journal of what it did.
    final class GoalRequestManager {
        var store: any GoalRequestStore
        var validator: GoalRequestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GoalRequestEngine

        init(store: any GoalRequestStore, validator: GoalRequestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GoalRequestEngine) {
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
                throw Kit.Failure("goal request \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GoalRequestStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("goal request \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GoalRequestStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("goal request \(code) not found")
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

    static func newGoalRequestManager(_ store: any GoalRequestStore, clock: any Kit.Clocks.Clock) -> GoalRequestManager {
        return GoalRequestManager(
            store: store,
            validator: defaultGoalRequestValidator(),
            clock: clock,
            journal: [],
            engine: defaultGoalRequestEngine()
        )
    }
}
