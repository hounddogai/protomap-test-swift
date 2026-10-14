import AcmePlatform
import Foundation

extension Labs {
    /// Moves accession audits through their life cycle and keeps a journal of what it did.
    final class AccessionAuditDesk {
        var store: any AccessionAuditStore
        var validator: AccessionAuditValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any AccessionAuditStore, validator: AccessionAuditValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("accession audit \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AccessionAuditStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("accession audit \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AccessionAuditStatus.failed)
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

    static func newAccessionAuditDesk(_ store: any AccessionAuditStore, clock: any Kit.Clocks.Clock) -> AccessionAuditDesk {
        return AccessionAuditDesk(
            store: store,
            validator: defaultAccessionAuditValidator(),
            clock: clock,
            journal: []
        )
    }
}
