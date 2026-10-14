import AcmePlatform
import Foundation

extension Referrals {
    /// Moves eligibility assignments through their life cycle and keeps a journal of what it did.
    final class EligibilityAssignmentManager {
        var store: any EligibilityAssignmentStore
        var validator: EligibilityAssignmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: EligibilityAssignmentEngine

        init(store: any EligibilityAssignmentStore, validator: EligibilityAssignmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: EligibilityAssignmentEngine) {
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
                throw Kit.Failure("eligibility assignment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(EligibilityAssignmentStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("eligibility assignment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(EligibilityAssignmentStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("eligibility assignment \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newEligibilityAssignmentManager(_ store: any EligibilityAssignmentStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> EligibilityAssignmentManager {
        return EligibilityAssignmentManager(
            store: store,
            validator: defaultEligibilityAssignmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultEligibilityAssignmentEngine(flags)
        )
    }
}
