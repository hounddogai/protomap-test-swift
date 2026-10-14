import AcmePlatform
import Foundation

extension Consent {
    /// Moves rolling proxy audits through their life cycle and keeps a journal of what it did.
    final class RollingProxyAuditCoordinator {
        var store: any RollingProxyAuditStore
        var validator: RollingProxyAuditValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RollingProxyAuditStore, validator: RollingProxyAuditValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling proxy audit \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingProxyAuditStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling proxy audit \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingProxyAuditStatus.withdrawn)
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

    static func newRollingProxyAuditCoordinator(_ store: any RollingProxyAuditStore, clock: any Kit.Clocks.Clock) -> RollingProxyAuditCoordinator {
        return RollingProxyAuditCoordinator(
            store: store,
            validator: defaultRollingProxyAuditValidator(),
            clock: clock,
            journal: []
        )
    }
}
