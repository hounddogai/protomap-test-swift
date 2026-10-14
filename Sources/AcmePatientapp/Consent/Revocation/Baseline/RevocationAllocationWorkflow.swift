import AcmePlatform
import Foundation

extension Consent {
    /// Moves revocation allocations through their life cycle and keeps a journal of what it did.
    final class RevocationAllocationDesk {
        var store: any RevocationAllocationStore
        var validator: RevocationAllocationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RevocationAllocationStore, validator: RevocationAllocationValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("revocation allocation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RevocationAllocationStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("revocation allocation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RevocationAllocationStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
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

    static func newRevocationAllocationDesk(_ store: any RevocationAllocationStore, clock: any Kit.Clocks.Clock) -> RevocationAllocationDesk {
        return RevocationAllocationDesk(
            store: store,
            validator: defaultRevocationAllocationValidator(),
            clock: clock,
            journal: []
        )
    }
}
