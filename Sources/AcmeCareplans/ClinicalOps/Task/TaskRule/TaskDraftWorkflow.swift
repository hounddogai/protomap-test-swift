import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves task drafts through their life cycle and keeps a journal of what it did.
    final class TaskDraftWorkflow {
        var store: any TaskDraftStore
        var validator: TaskDraftValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any TaskDraftStore, validator: TaskDraftValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("task draft \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TaskDraftStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("task draft \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TaskDraftStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newTaskDraftWorkflow(_ store: any TaskDraftStore, clock: any Kit.Clocks.Clock) -> TaskDraftWorkflow {
        return TaskDraftWorkflow(store: store, validator: defaultTaskDraftValidator(), clock: clock, journal: [])
    }
}
