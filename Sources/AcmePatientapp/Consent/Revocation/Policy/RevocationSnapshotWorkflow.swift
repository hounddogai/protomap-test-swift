import AcmePlatform
import Foundation

extension Consent {
    /// Moves revocation snapshots through their life cycle and keeps a journal of what it did.
    final class RevocationSnapshotDesk {
        var store: any RevocationSnapshotStore
        var validator: RevocationSnapshotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RevocationSnapshotStore, validator: RevocationSnapshotValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("revocation snapshot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RevocationSnapshotStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("revocation snapshot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RevocationSnapshotStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newRevocationSnapshotDesk(_ store: any RevocationSnapshotStore, clock: any Kit.Clocks.Clock) -> RevocationSnapshotDesk {
        return RevocationSnapshotDesk(
            store: store,
            validator: defaultRevocationSnapshotValidator(),
            clock: clock,
            journal: []
        )
    }
}
