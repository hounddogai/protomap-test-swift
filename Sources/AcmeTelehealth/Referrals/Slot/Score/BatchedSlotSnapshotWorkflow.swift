import AcmePlatform
import Foundation

extension Referrals {
    /// Moves batched slot snapshots through their life cycle and keeps a journal of what it did.
    final class BatchedSlotSnapshotService {
        var store: any BatchedSlotSnapshotStore
        var validator: BatchedSlotSnapshotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BatchedSlotSnapshotEngine

        init(store: any BatchedSlotSnapshotStore, validator: BatchedSlotSnapshotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BatchedSlotSnapshotEngine) {
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
                throw Kit.Failure("batched slot snapshot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedSlotSnapshotStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched slot snapshot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedSlotSnapshotStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched slot snapshot \(code) not found")
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

    static func newBatchedSlotSnapshotService(_ store: any BatchedSlotSnapshotStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> BatchedSlotSnapshotService {
        return BatchedSlotSnapshotService(
            store: store,
            validator: defaultBatchedSlotSnapshotValidator(),
            clock: clock,
            journal: [],
            engine: defaultBatchedSlotSnapshotEngine(flags)
        )
    }
}
