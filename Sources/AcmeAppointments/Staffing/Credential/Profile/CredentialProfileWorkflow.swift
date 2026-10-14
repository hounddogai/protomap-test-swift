import AcmePlatform
import Foundation

extension Staffing {
    /// Moves credential profiles through their life cycle and keeps a journal of what it did.
    final class CredentialProfileDesk {
        var store: any CredentialProfileStore
        var validator: CredentialProfileValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CredentialProfileStore, validator: CredentialProfileValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("credential profile \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CredentialProfileStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("credential profile \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CredentialProfileStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
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

    static func newCredentialProfileDesk(_ store: any CredentialProfileStore, clock: any Kit.Clocks.Clock) -> CredentialProfileDesk {
        return CredentialProfileDesk(
            store: store,
            validator: defaultCredentialProfileValidator(),
            clock: clock,
            journal: []
        )
    }
}
