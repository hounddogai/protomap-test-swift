import AcmePlatform
import Foundation

extension Referrals {
    /// Moves batched slot quotas through their life cycle and keeps a journal of what it did.
    final class BatchedSlotQuotaService {
        var store: any BatchedSlotQuotaStore
        var validator: BatchedSlotQuotaValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BatchedSlotQuotaEngine

        init(store: any BatchedSlotQuotaStore, validator: BatchedSlotQuotaValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BatchedSlotQuotaEngine) {
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
                throw Kit.Failure("batched slot quota \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedSlotQuotaStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched slot quota \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedSlotQuotaStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched slot quota \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newBatchedSlotQuotaService(_ store: any BatchedSlotQuotaStore, clock: any Kit.Clocks.Clock) -> BatchedSlotQuotaService {
        return BatchedSlotQuotaService(
            store: store,
            validator: defaultBatchedSlotQuotaValidator(),
            clock: clock,
            journal: [],
            engine: defaultBatchedSlotQuotaEngine()
        )
    }
}
