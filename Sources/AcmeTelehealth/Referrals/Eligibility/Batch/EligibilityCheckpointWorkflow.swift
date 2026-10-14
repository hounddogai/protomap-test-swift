import AcmePlatform
import Foundation

extension Referrals {
    /// Moves eligibility checkpoints through their life cycle and keeps a journal of what it did.
    final class EligibilityCheckpointWorkflow {
        var store: any EligibilityCheckpointStore
        var validator: EligibilityCheckpointValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: EligibilityCheckpointEngine

        init(store: any EligibilityCheckpointStore, validator: EligibilityCheckpointValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: EligibilityCheckpointEngine) {
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
                throw Kit.Failure("eligibility checkpoint \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(EligibilityCheckpointStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("eligibility checkpoint \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(EligibilityCheckpointStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("eligibility checkpoint \(code) not found")
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

    static func newEligibilityCheckpointWorkflow(_ store: any EligibilityCheckpointStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> EligibilityCheckpointWorkflow {
        return EligibilityCheckpointWorkflow(
            store: store,
            validator: defaultEligibilityCheckpointValidator(),
            clock: clock,
            journal: [],
            engine: defaultEligibilityCheckpointEngine(flags)
        )
    }
}
