import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves scheduled goal preferences through their life cycle and keeps a journal of what it did.
    final class ScheduledGoalPreferenceCoordinator {
        var store: any ScheduledGoalPreferenceStore
        var validator: ScheduledGoalPreferenceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ScheduledGoalPreferenceEngine

        init(store: any ScheduledGoalPreferenceStore, validator: ScheduledGoalPreferenceValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ScheduledGoalPreferenceEngine) {
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
                throw Kit.Failure("scheduled goal preference \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledGoalPreferenceStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled goal preference \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledGoalPreferenceStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled goal preference \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newScheduledGoalPreferenceCoordinator(_ store: any ScheduledGoalPreferenceStore, clock: any Kit.Clocks.Clock) -> ScheduledGoalPreferenceCoordinator {
        return ScheduledGoalPreferenceCoordinator(
            store: store,
            validator: defaultScheduledGoalPreferenceValidator(),
            clock: clock,
            journal: [],
            engine: defaultScheduledGoalPreferenceEngine()
        )
    }
}
