import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves rolling care protocol audits through their life cycle and keeps a journal of what it did.
    final class RollingCareProtocolAuditManager {
        var store: any RollingCareProtocolAuditStore
        var validator: RollingCareProtocolAuditValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RollingCareProtocolAuditStore, validator: RollingCareProtocolAuditValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("rolling care protocol audit \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingCareProtocolAuditStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling care protocol audit \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingCareProtocolAuditStatus.closed)
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

    static func newRollingCareProtocolAuditManager(_ store: any RollingCareProtocolAuditStore, clock: any Kit.Clocks.Clock) -> RollingCareProtocolAuditManager {
        return RollingCareProtocolAuditManager(
            store: store,
            validator: defaultRollingCareProtocolAuditValidator(),
            clock: clock,
            journal: []
        )
    }
}
