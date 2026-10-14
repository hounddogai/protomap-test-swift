import AcmePlatform
import Foundation

extension Staffing {
    /// Moves credential drafts through their life cycle and keeps a journal of what it did.
    final class CredentialDraftDesk {
        var store: any CredentialDraftStore
        var validator: CredentialDraftValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CredentialDraftStore, validator: CredentialDraftValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("credential draft \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CredentialDraftStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("credential draft \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CredentialDraftStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
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

    static func newCredentialDraftDesk(_ store: any CredentialDraftStore, clock: any Kit.Clocks.Clock) -> CredentialDraftDesk {
        return CredentialDraftDesk(
            store: store,
            validator: defaultCredentialDraftValidator(),
            clock: clock,
            journal: []
        )
    }
}
