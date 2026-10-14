import AcmePlatform
import Foundation

extension Referrals {
    /// Moves scheduled follow up audits through their life cycle and keeps a journal of what it did.
    final class ScheduledFollowUpAuditWorkflow {
        var store: any ScheduledFollowUpAuditStore
        var validator: ScheduledFollowUpAuditValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ScheduledFollowUpAuditEngine

        init(store: any ScheduledFollowUpAuditStore, validator: ScheduledFollowUpAuditValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ScheduledFollowUpAuditEngine) {
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
                throw Kit.Failure("scheduled follow up audit \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledFollowUpAuditStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled follow up audit \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledFollowUpAuditStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled follow up audit \(code) not found")
            }
            let result = engine.run(item)
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

    static func newScheduledFollowUpAuditWorkflow(_ store: any ScheduledFollowUpAuditStore, clock: any Kit.Clocks.Clock) -> ScheduledFollowUpAuditWorkflow {
        return ScheduledFollowUpAuditWorkflow(
            store: store,
            validator: defaultScheduledFollowUpAuditValidator(),
            clock: clock,
            journal: [],
            engine: defaultScheduledFollowUpAuditEngine()
        )
    }
}
