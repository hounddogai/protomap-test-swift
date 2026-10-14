import AcmePlatform
import Foundation

extension Consent {
    /// Moves pending revocation claims through their life cycle and keeps a journal of what it did.
    final class PendingRevocationClaimManager {
        var store: any PendingRevocationClaimStore
        var validator: PendingRevocationClaimValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PendingRevocationClaimStore, validator: PendingRevocationClaimValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("pending revocation claim \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingRevocationClaimStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending revocation claim \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingRevocationClaimStatus.cancelled)
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

    static func newPendingRevocationClaimManager(_ store: any PendingRevocationClaimStore, clock: any Kit.Clocks.Clock) -> PendingRevocationClaimManager {
        return PendingRevocationClaimManager(
            store: store,
            validator: defaultPendingRevocationClaimValidator(),
            clock: clock,
            journal: []
        )
    }
}
