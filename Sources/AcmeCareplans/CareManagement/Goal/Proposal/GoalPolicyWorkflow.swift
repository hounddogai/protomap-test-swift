import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves goal policies through their life cycle and keeps a journal of what it did.
    final class GoalPolicyCoordinator {
        var store: any GoalPolicyStore
        var validator: GoalPolicyValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GoalPolicyEngine

        init(store: any GoalPolicyStore, validator: GoalPolicyValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GoalPolicyEngine) {
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
                throw Kit.Failure("goal policy \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GoalPolicyStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("goal policy \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GoalPolicyStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("goal policy \(code) not found")
            }
            let result = engine.price(item)
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

    static func newGoalPolicyCoordinator(_ store: any GoalPolicyStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> GoalPolicyCoordinator {
        return GoalPolicyCoordinator(
            store: store,
            validator: defaultGoalPolicyValidator(),
            clock: clock,
            journal: [],
            engine: defaultGoalPolicyEngine(flags)
        )
    }
}
