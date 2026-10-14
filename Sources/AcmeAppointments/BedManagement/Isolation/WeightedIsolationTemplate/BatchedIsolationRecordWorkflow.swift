import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves batched isolation records through their life cycle and keeps a journal of what it did.
    final class BatchedIsolationRecordManager {
        var store: any BatchedIsolationRecordStore
        var validator: BatchedIsolationRecordValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BatchedIsolationRecordEngine

        init(store: any BatchedIsolationRecordStore, validator: BatchedIsolationRecordValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BatchedIsolationRecordEngine) {
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
                throw Kit.Failure("batched isolation record \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedIsolationRecordStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched isolation record \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedIsolationRecordStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched isolation record \(code) not found")
            }
            let result = engine.price(item)
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

    static func newBatchedIsolationRecordManager(_ store: any BatchedIsolationRecordStore, clock: any Kit.Clocks.Clock) -> BatchedIsolationRecordManager {
        return BatchedIsolationRecordManager(
            store: store,
            validator: defaultBatchedIsolationRecordValidator(),
            clock: clock,
            journal: [],
            engine: defaultBatchedIsolationRecordEngine()
        )
    }
}
