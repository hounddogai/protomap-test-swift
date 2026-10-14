import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves scheduled task segments through their life cycle and keeps a journal of what it did.
    final class ScheduledTaskSegmentWorkflow {
        var store: any ScheduledTaskSegmentStore
        var validator: ScheduledTaskSegmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ScheduledTaskSegmentStore, validator: ScheduledTaskSegmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("scheduled task segment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledTaskSegmentStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled task segment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledTaskSegmentStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
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

    static func newScheduledTaskSegmentWorkflow(_ store: any ScheduledTaskSegmentStore, clock: any Kit.Clocks.Clock) -> ScheduledTaskSegmentWorkflow {
        return ScheduledTaskSegmentWorkflow(
            store: store,
            validator: defaultScheduledTaskSegmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
