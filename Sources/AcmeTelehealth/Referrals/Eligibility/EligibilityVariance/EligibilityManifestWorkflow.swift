import AcmePlatform
import Foundation

extension Referrals {
    /// Moves eligibility manifests through their life cycle and keeps a journal of what it did.
    final class EligibilityManifestWorkflow {
        var store: any EligibilityManifestStore
        var validator: EligibilityManifestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any EligibilityManifestStore, validator: EligibilityManifestValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("eligibility manifest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(EligibilityManifestStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("eligibility manifest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(EligibilityManifestStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
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

    static func newEligibilityManifestWorkflow(_ store: any EligibilityManifestStore, clock: any Kit.Clocks.Clock) -> EligibilityManifestWorkflow {
        return EligibilityManifestWorkflow(
            store: store,
            validator: defaultEligibilityManifestValidator(),
            clock: clock,
            journal: []
        )
    }
}
