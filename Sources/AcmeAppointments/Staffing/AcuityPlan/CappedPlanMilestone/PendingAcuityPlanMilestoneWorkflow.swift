import AcmePlatform
import Foundation

extension Staffing {
    /// Moves pending acuity plan milestones through their life cycle and keeps a journal of what it did.
    final class PendingAcuityPlanMilestoneDesk {
        var store: any PendingAcuityPlanMilestoneStore
        var validator: PendingAcuityPlanMilestoneValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PendingAcuityPlanMilestoneStore, validator: PendingAcuityPlanMilestoneValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("pending acuity plan milestone \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingAcuityPlanMilestoneStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending acuity plan milestone \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingAcuityPlanMilestoneStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
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

    static func newPendingAcuityPlanMilestoneDesk(_ store: any PendingAcuityPlanMilestoneStore, clock: any Kit.Clocks.Clock) -> PendingAcuityPlanMilestoneDesk {
        return PendingAcuityPlanMilestoneDesk(
            store: store,
            validator: defaultPendingAcuityPlanMilestoneValidator(),
            clock: clock,
            journal: []
        )
    }
}
