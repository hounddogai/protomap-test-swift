import AcmePlatform
import Foundation

extension Consent {
    /// Moves witness audits through their life cycle and keeps a journal of what it did.
    final class WitnessAuditService {
        var store: any WitnessAuditStore
        var validator: WitnessAuditValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any WitnessAuditStore, validator: WitnessAuditValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("witness audit \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WitnessAuditStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("witness audit \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WitnessAuditStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
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

    static func newWitnessAuditService(_ store: any WitnessAuditStore, clock: any Kit.Clocks.Clock) -> WitnessAuditService {
        return WitnessAuditService(
            store: store,
            validator: defaultWitnessAuditValidator(),
            clock: clock,
            journal: []
        )
    }
}
