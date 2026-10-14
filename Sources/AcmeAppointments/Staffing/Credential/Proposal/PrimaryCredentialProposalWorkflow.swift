import AcmePlatform
import Foundation

extension Staffing {
    /// Moves primary credential proposals through their life cycle and keeps a journal of what it did.
    final class PrimaryCredentialProposalWorkflow {
        var store: any PrimaryCredentialProposalStore
        var validator: PrimaryCredentialProposalValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PrimaryCredentialProposalStore, validator: PrimaryCredentialProposalValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary credential proposal \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryCredentialProposalStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary credential proposal \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryCredentialProposalStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newPrimaryCredentialProposalWorkflow(_ store: any PrimaryCredentialProposalStore, clock: any Kit.Clocks.Clock) -> PrimaryCredentialProposalWorkflow {
        return PrimaryCredentialProposalWorkflow(
            store: store,
            validator: defaultPrimaryCredentialProposalValidator(),
            clock: clock,
            journal: []
        )
    }
}
