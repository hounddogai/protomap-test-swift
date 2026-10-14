import AcmePlatform
import Foundation

extension Consent {
    /// Moves manual consent form proposals through their life cycle and keeps a journal of what it did.
    final class ManualConsentFormProposalWorkflow {
        var store: any ManualConsentFormProposalStore
        var validator: ManualConsentFormProposalValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ManualConsentFormProposalStore, validator: ManualConsentFormProposalValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual consent form proposal \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualConsentFormProposalStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual consent form proposal \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualConsentFormProposalStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newManualConsentFormProposalWorkflow(_ store: any ManualConsentFormProposalStore, clock: any Kit.Clocks.Clock) -> ManualConsentFormProposalWorkflow {
        return ManualConsentFormProposalWorkflow(
            store: store,
            validator: defaultManualConsentFormProposalValidator(),
            clock: clock,
            journal: []
        )
    }
}
