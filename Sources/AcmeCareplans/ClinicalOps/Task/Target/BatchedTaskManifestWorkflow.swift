import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves batched task manifests through their life cycle and keeps a journal of what it did.
    final class BatchedTaskManifestManager {
        var store: any BatchedTaskManifestStore
        var validator: BatchedTaskManifestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BatchedTaskManifestEngine

        init(store: any BatchedTaskManifestStore, validator: BatchedTaskManifestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BatchedTaskManifestEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched task manifest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedTaskManifestStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched task manifest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedTaskManifestStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched task manifest \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newBatchedTaskManifestManager(_ store: any BatchedTaskManifestStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> BatchedTaskManifestManager {
        return BatchedTaskManifestManager(
            store: store,
            validator: defaultBatchedTaskManifestValidator(),
            clock: clock,
            journal: [],
            engine: defaultBatchedTaskManifestEngine(flags)
        )
    }
}
