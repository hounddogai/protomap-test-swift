import AcmePlatform
import Foundation

extension Consent {
    /// Moves revocation digests through their life cycle and keeps a journal of what it did.
    final class RevocationDigestDesk {
        var store: any RevocationDigestStore
        var validator: RevocationDigestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RevocationDigestStore, validator: RevocationDigestValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("revocation digest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RevocationDigestStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("revocation digest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RevocationDigestStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
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

    static func newRevocationDigestDesk(_ store: any RevocationDigestStore, clock: any Kit.Clocks.Clock) -> RevocationDigestDesk {
        return RevocationDigestDesk(
            store: store,
            validator: defaultRevocationDigestValidator(),
            clock: clock,
            journal: []
        )
    }
}
