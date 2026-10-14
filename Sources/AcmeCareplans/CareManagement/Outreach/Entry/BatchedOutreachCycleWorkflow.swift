import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves batched outreach cycles through their life cycle and keeps a journal of what it did.
    final class BatchedOutreachCycleManager {
        var store: any BatchedOutreachCycleStore
        var validator: BatchedOutreachCycleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BatchedOutreachCycleEngine

        init(store: any BatchedOutreachCycleStore, validator: BatchedOutreachCycleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BatchedOutreachCycleEngine) {
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
                throw Kit.Failure("batched outreach cycle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedOutreachCycleStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched outreach cycle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedOutreachCycleStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched outreach cycle \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newBatchedOutreachCycleManager(_ store: any BatchedOutreachCycleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> BatchedOutreachCycleManager {
        return BatchedOutreachCycleManager(
            store: store,
            validator: defaultBatchedOutreachCycleValidator(),
            clock: clock,
            journal: [],
            engine: defaultBatchedOutreachCycleEngine(flags)
        )
    }
}
