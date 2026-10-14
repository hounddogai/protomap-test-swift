import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves scheduled formulary milestones through their life cycle and keeps a journal of what it did.
    final class ScheduledFormularyMilestoneWorkflow {
        var store: any ScheduledFormularyMilestoneStore
        var validator: ScheduledFormularyMilestoneValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ScheduledFormularyMilestoneStore, validator: ScheduledFormularyMilestoneValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("scheduled formulary milestone \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledFormularyMilestoneStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled formulary milestone \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledFormularyMilestoneStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newScheduledFormularyMilestoneWorkflow(_ store: any ScheduledFormularyMilestoneStore, clock: any Kit.Clocks.Clock) -> ScheduledFormularyMilestoneWorkflow {
        return ScheduledFormularyMilestoneWorkflow(
            store: store,
            validator: defaultScheduledFormularyMilestoneValidator(),
            clock: clock,
            journal: []
        )
    }
}
