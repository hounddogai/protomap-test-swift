import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves task manifests through their life cycle and keeps a journal of what it did.
    final class TaskManifestCoordinator {
        var store: any TaskManifestStore
        var validator: TaskManifestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TaskManifestEngine

        init(store: any TaskManifestStore, validator: TaskManifestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TaskManifestEngine) {
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
                throw Kit.Failure("task manifest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TaskManifestStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("task manifest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TaskManifestStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("task manifest \(code) not found")
            }
            let result = engine.price(item)
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

    static func newTaskManifestCoordinator(_ store: any TaskManifestStore, clock: any Kit.Clocks.Clock) -> TaskManifestCoordinator {
        return TaskManifestCoordinator(
            store: store,
            validator: defaultTaskManifestValidator(),
            clock: clock,
            journal: [],
            engine: defaultTaskManifestEngine()
        )
    }
}
