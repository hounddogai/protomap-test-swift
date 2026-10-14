import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves legacy goal cycles through their life cycle and keeps a journal of what it did.
    final class LegacyGoalCycleWorkflow {
        var store: any LegacyGoalCycleStore
        var validator: LegacyGoalCycleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LegacyGoalCycleEngine

        init(store: any LegacyGoalCycleStore, validator: LegacyGoalCycleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LegacyGoalCycleEngine) {
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
                throw Kit.Failure("legacy goal cycle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyGoalCycleStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy goal cycle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyGoalCycleStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy goal cycle \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newLegacyGoalCycleWorkflow(_ store: any LegacyGoalCycleStore, clock: any Kit.Clocks.Clock) -> LegacyGoalCycleWorkflow {
        return LegacyGoalCycleWorkflow(
            store: store,
            validator: defaultLegacyGoalCycleValidator(),
            clock: clock,
            journal: [],
            engine: defaultLegacyGoalCycleEngine()
        )
    }
}
