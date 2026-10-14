import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves batched charge entries through their life cycle and keeps a journal of what it did.
    final class BatchedChargeEntryDesk {
        var store: any BatchedChargeEntryStore
        var validator: BatchedChargeEntryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BatchedChargeEntryEngine

        init(store: any BatchedChargeEntryStore, validator: BatchedChargeEntryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BatchedChargeEntryEngine) {
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
                throw Kit.Failure("batched charge entry \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedChargeEntryStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched charge entry \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedChargeEntryStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched charge entry \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newBatchedChargeEntryDesk(_ store: any BatchedChargeEntryStore, clock: any Kit.Clocks.Clock) -> BatchedChargeEntryDesk {
        return BatchedChargeEntryDesk(
            store: store,
            validator: defaultBatchedChargeEntryValidator(),
            clock: clock,
            journal: [],
            engine: defaultBatchedChargeEntryEngine()
        )
    }
}
