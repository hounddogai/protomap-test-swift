import AcmePlatform
import Foundation

extension Labs {
    /// Moves pending courier milestones through their life cycle and keeps a journal of what it did.
    final class PendingCourierMilestoneWorkflow {
        var store: any PendingCourierMilestoneStore
        var validator: PendingCourierMilestoneValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PendingCourierMilestoneStore, validator: PendingCourierMilestoneValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("pending courier milestone \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingCourierMilestoneStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending courier milestone \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingCourierMilestoneStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
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

    static func newPendingCourierMilestoneWorkflow(_ store: any PendingCourierMilestoneStore, clock: any Kit.Clocks.Clock) -> PendingCourierMilestoneWorkflow {
        return PendingCourierMilestoneWorkflow(
            store: store,
            validator: defaultPendingCourierMilestoneValidator(),
            clock: clock,
            journal: []
        )
    }
}
