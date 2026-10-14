import AcmePlatform
import Foundation

extension Imaging {
    /// Moves scheduled modality audits through their life cycle and keeps a journal of what it did.
    final class ScheduledModalityAuditDesk {
        var store: any ScheduledModalityAuditStore
        var validator: ScheduledModalityAuditValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ScheduledModalityAuditEngine

        init(store: any ScheduledModalityAuditStore, validator: ScheduledModalityAuditValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ScheduledModalityAuditEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled modality audit \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledModalityAuditStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled modality audit \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledModalityAuditStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled modality audit \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newScheduledModalityAuditDesk(_ store: any ScheduledModalityAuditStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ScheduledModalityAuditDesk {
        return ScheduledModalityAuditDesk(
            store: store,
            validator: defaultScheduledModalityAuditValidator(),
            clock: clock,
            journal: [],
            engine: defaultScheduledModalityAuditEngine(flags)
        )
    }
}
