import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves weighted goal cycles through their life cycle and keeps a journal of what it did.
    final class WeightedGoalCycleDesk {
        var store: any WeightedGoalCycleStore
        var validator: WeightedGoalCycleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WeightedGoalCycleEngine

        init(store: any WeightedGoalCycleStore, validator: WeightedGoalCycleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WeightedGoalCycleEngine) {
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
                throw Kit.Failure("weighted goal cycle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedGoalCycleStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted goal cycle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedGoalCycleStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted goal cycle \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newWeightedGoalCycleDesk(_ store: any WeightedGoalCycleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> WeightedGoalCycleDesk {
        return WeightedGoalCycleDesk(
            store: store,
            validator: defaultWeightedGoalCycleValidator(),
            clock: clock,
            journal: [],
            engine: defaultWeightedGoalCycleEngine(flags)
        )
    }
}
