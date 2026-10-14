import AcmePlatform
import Foundation

extension Imaging {
    /// Moves rolling modality audits through their life cycle and keeps a journal of what it did.
    final class RollingModalityAuditWorkflow {
        var store: any RollingModalityAuditStore
        var validator: RollingModalityAuditValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RollingModalityAuditStore, validator: RollingModalityAuditValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("rolling modality audit \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingModalityAuditStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling modality audit \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingModalityAuditStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
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

    static func newRollingModalityAuditWorkflow(_ store: any RollingModalityAuditStore, clock: any Kit.Clocks.Clock) -> RollingModalityAuditWorkflow {
        return RollingModalityAuditWorkflow(
            store: store,
            validator: defaultRollingModalityAuditValidator(),
            clock: clock,
            journal: []
        )
    }
}
