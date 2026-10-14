import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves task segments through their life cycle and keeps a journal of what it did.
    final class TaskSegmentCoordinator {
        var store: any TaskSegmentStore
        var validator: TaskSegmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TaskSegmentEngine

        init(store: any TaskSegmentStore, validator: TaskSegmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TaskSegmentEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("task segment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TaskSegmentStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("task segment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TaskSegmentStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("task segment \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newTaskSegmentCoordinator(_ store: any TaskSegmentStore, clock: any Kit.Clocks.Clock) -> TaskSegmentCoordinator {
        return TaskSegmentCoordinator(
            store: store,
            validator: defaultTaskSegmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultTaskSegmentEngine()
        )
    }
}
