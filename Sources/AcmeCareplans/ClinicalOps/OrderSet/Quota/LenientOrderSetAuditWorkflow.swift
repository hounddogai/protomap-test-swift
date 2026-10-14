import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves lenient order set audits through their life cycle and keeps a journal of what it did.
    final class LenientOrderSetAuditDesk {
        var store: any LenientOrderSetAuditStore
        var validator: LenientOrderSetAuditValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any LenientOrderSetAuditStore, validator: LenientOrderSetAuditValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("lenient order set audit \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientOrderSetAuditStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient order set audit \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientOrderSetAuditStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
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

    static func newLenientOrderSetAuditDesk(_ store: any LenientOrderSetAuditStore, clock: any Kit.Clocks.Clock) -> LenientOrderSetAuditDesk {
        return LenientOrderSetAuditDesk(
            store: store,
            validator: defaultLenientOrderSetAuditValidator(),
            clock: clock,
            journal: []
        )
    }
}
