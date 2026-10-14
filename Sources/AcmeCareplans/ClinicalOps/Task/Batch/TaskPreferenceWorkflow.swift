import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves task preferences through their life cycle and keeps a journal of what it did.
    final class TaskPreferenceDesk {
        var store: any TaskPreferenceStore
        var validator: TaskPreferenceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any TaskPreferenceStore, validator: TaskPreferenceValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("task preference \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TaskPreferenceStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("task preference \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TaskPreferenceStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
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

    static func newTaskPreferenceDesk(_ store: any TaskPreferenceStore, clock: any Kit.Clocks.Clock) -> TaskPreferenceDesk {
        return TaskPreferenceDesk(
            store: store,
            validator: defaultTaskPreferenceValidator(),
            clock: clock,
            journal: []
        )
    }
}
