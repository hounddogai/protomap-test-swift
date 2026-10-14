import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves task groups through their life cycle and keeps a journal of what it did.
    final class TaskGroupService {
        var store: any TaskGroupStore
        var validator: TaskGroupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TaskGroupEngine

        init(store: any TaskGroupStore, validator: TaskGroupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TaskGroupEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("task group \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TaskGroupStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("task group \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TaskGroupStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("task group \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newTaskGroupService(_ store: any TaskGroupStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> TaskGroupService {
        return TaskGroupService(
            store: store,
            validator: defaultTaskGroupValidator(),
            clock: clock,
            journal: [],
            engine: defaultTaskGroupEngine(flags)
        )
    }
}
