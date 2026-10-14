import AcmePlatform
import Foundation

extension Referrals {
    /// Moves eligibility snapshots through their life cycle and keeps a journal of what it did.
    final class EligibilitySnapshotWorkflow {
        var store: any EligibilitySnapshotStore
        var validator: EligibilitySnapshotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: EligibilitySnapshotEngine

        init(store: any EligibilitySnapshotStore, validator: EligibilitySnapshotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: EligibilitySnapshotEngine) {
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
                throw Kit.Failure("eligibility snapshot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(EligibilitySnapshotStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("eligibility snapshot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(EligibilitySnapshotStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("eligibility snapshot \(code) not found")
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

    static func newEligibilitySnapshotWorkflow(_ store: any EligibilitySnapshotStore, clock: any Kit.Clocks.Clock) -> EligibilitySnapshotWorkflow {
        return EligibilitySnapshotWorkflow(
            store: store,
            validator: defaultEligibilitySnapshotValidator(),
            clock: clock,
            journal: [],
            engine: defaultEligibilitySnapshotEngine()
        )
    }
}
