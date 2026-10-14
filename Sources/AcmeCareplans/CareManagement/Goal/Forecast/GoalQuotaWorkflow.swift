import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves goal quotas through their life cycle and keeps a journal of what it did.
    final class GoalQuotaCoordinator {
        var store: any GoalQuotaStore
        var validator: GoalQuotaValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GoalQuotaEngine

        init(store: any GoalQuotaStore, validator: GoalQuotaValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GoalQuotaEngine) {
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
                throw Kit.Failure("goal quota \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GoalQuotaStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("goal quota \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GoalQuotaStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("goal quota \(code) not found")
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

    static func newGoalQuotaCoordinator(_ store: any GoalQuotaStore, clock: any Kit.Clocks.Clock) -> GoalQuotaCoordinator {
        return GoalQuotaCoordinator(
            store: store,
            validator: defaultGoalQuotaValidator(),
            clock: clock,
            journal: [],
            engine: defaultGoalQuotaEngine()
        )
    }
}
