import AcmePlatform
import Foundation

extension Consent {
    /// Moves primary consent form assignments through their life cycle and keeps a journal of what it did.
    final class PrimaryConsentFormAssignmentWorkflow {
        var store: any PrimaryConsentFormAssignmentStore
        var validator: PrimaryConsentFormAssignmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PrimaryConsentFormAssignmentStore, validator: PrimaryConsentFormAssignmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("primary consent form assignment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryConsentFormAssignmentStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary consent form assignment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryConsentFormAssignmentStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
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

    static func newPrimaryConsentFormAssignmentWorkflow(_ store: any PrimaryConsentFormAssignmentStore, clock: any Kit.Clocks.Clock) -> PrimaryConsentFormAssignmentWorkflow {
        return PrimaryConsentFormAssignmentWorkflow(
            store: store,
            validator: defaultPrimaryConsentFormAssignmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
