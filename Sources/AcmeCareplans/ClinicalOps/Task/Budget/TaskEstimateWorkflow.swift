import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves task estimates through their life cycle and keeps a journal of what it did.
    final class TaskEstimateCoordinator {
        var store: any TaskEstimateStore
        var validator: TaskEstimateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TaskEstimateEngine

        init(store: any TaskEstimateStore, validator: TaskEstimateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TaskEstimateEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("task estimate \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TaskEstimateStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("task estimate \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TaskEstimateStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("task estimate \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newTaskEstimateCoordinator(_ store: any TaskEstimateStore, clock: any Kit.Clocks.Clock) -> TaskEstimateCoordinator {
        return TaskEstimateCoordinator(
            store: store,
            validator: defaultTaskEstimateValidator(),
            clock: clock,
            journal: [],
            engine: defaultTaskEstimateEngine()
        )
    }
}
