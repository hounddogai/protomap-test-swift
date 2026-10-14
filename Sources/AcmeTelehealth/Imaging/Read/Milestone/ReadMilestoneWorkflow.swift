import AcmePlatform
import Foundation

extension Imaging {
    /// Moves read milestones through their life cycle and keeps a journal of what it did.
    final class ReadMilestoneWorkflow {
        var store: any ReadMilestoneStore
        var validator: ReadMilestoneValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ReadMilestoneStore, validator: ReadMilestoneValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("read milestone \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ReadMilestoneStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("read milestone \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ReadMilestoneStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
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

    static func newReadMilestoneWorkflow(_ store: any ReadMilestoneStore, clock: any Kit.Clocks.Clock) -> ReadMilestoneWorkflow {
        return ReadMilestoneWorkflow(
            store: store,
            validator: defaultReadMilestoneValidator(),
            clock: clock,
            journal: []
        )
    }
}
