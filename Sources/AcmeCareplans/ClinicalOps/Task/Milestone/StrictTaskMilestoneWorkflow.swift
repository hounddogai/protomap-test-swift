import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves strict task milestones through their life cycle and keeps a journal of what it did.
    final class StrictTaskMilestoneService {
        var store: any StrictTaskMilestoneStore
        var validator: StrictTaskMilestoneValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: StrictTaskMilestoneEngine

        init(store: any StrictTaskMilestoneStore, validator: StrictTaskMilestoneValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: StrictTaskMilestoneEngine) {
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
                throw Kit.Failure("strict task milestone \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictTaskMilestoneStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict task milestone \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictTaskMilestoneStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict task milestone \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newStrictTaskMilestoneService(_ store: any StrictTaskMilestoneStore, clock: any Kit.Clocks.Clock) -> StrictTaskMilestoneService {
        return StrictTaskMilestoneService(
            store: store,
            validator: defaultStrictTaskMilestoneValidator(),
            clock: clock,
            journal: [],
            engine: defaultStrictTaskMilestoneEngine()
        )
    }
}
