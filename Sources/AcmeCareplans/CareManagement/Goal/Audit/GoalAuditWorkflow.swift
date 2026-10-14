import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves goal audits through their life cycle and keeps a journal of what it did.
    final class GoalAuditWorkflow {
        var store: any GoalAuditStore
        var validator: GoalAuditValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any GoalAuditStore, validator: GoalAuditValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("goal audit \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GoalAuditStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("goal audit \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GoalAuditStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
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

    static func newGoalAuditWorkflow(_ store: any GoalAuditStore, clock: any Kit.Clocks.Clock) -> GoalAuditWorkflow {
        return GoalAuditWorkflow(store: store, validator: defaultGoalAuditValidator(), clock: clock, journal: [])
    }
}
