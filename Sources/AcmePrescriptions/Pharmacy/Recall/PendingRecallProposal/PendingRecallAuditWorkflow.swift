import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves pending recall audits through their life cycle and keeps a journal of what it did.
    final class PendingRecallAuditDesk {
        var store: any PendingRecallAuditStore
        var validator: PendingRecallAuditValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PendingRecallAuditStore, validator: PendingRecallAuditValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("pending recall audit \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingRecallAuditStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending recall audit \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingRecallAuditStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
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

    static func newPendingRecallAuditDesk(_ store: any PendingRecallAuditStore, clock: any Kit.Clocks.Clock) -> PendingRecallAuditDesk {
        return PendingRecallAuditDesk(
            store: store,
            validator: defaultPendingRecallAuditValidator(),
            clock: clock,
            journal: []
        )
    }
}
