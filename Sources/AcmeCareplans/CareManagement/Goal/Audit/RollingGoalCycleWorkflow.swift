import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves rolling goal cycles through their life cycle and keeps a journal of what it did.
    final class RollingGoalCycleCoordinator {
        var store: any RollingGoalCycleStore
        var validator: RollingGoalCycleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RollingGoalCycleEngine

        init(store: any RollingGoalCycleStore, validator: RollingGoalCycleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RollingGoalCycleEngine) {
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
                throw Kit.Failure("rolling goal cycle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingGoalCycleStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling goal cycle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingGoalCycleStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling goal cycle \(code) not found")
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

    static func newRollingGoalCycleCoordinator(_ store: any RollingGoalCycleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RollingGoalCycleCoordinator {
        return RollingGoalCycleCoordinator(
            store: store,
            validator: defaultRollingGoalCycleValidator(),
            clock: clock,
            journal: [],
            engine: defaultRollingGoalCycleEngine(flags)
        )
    }
}
