import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves task templates through their life cycle and keeps a journal of what it did.
    final class TaskTemplateCoordinator {
        var store: any TaskTemplateStore
        var validator: TaskTemplateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any TaskTemplateStore, validator: TaskTemplateValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("task template \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TaskTemplateStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("task template \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TaskTemplateStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
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

    static func newTaskTemplateCoordinator(_ store: any TaskTemplateStore, clock: any Kit.Clocks.Clock) -> TaskTemplateCoordinator {
        return TaskTemplateCoordinator(
            store: store,
            validator: defaultTaskTemplateValidator(),
            clock: clock,
            journal: []
        )
    }
}
