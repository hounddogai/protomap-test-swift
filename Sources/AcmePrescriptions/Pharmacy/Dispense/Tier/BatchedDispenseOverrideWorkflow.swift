import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves batched dispense overrides through their life cycle and keeps a journal of what it did.
    final class BatchedDispenseOverrideCoordinator {
        var store: any BatchedDispenseOverrideStore
        var validator: BatchedDispenseOverrideValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BatchedDispenseOverrideEngine

        init(store: any BatchedDispenseOverrideStore, validator: BatchedDispenseOverrideValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BatchedDispenseOverrideEngine) {
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
                throw Kit.Failure("batched dispense override \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedDispenseOverrideStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched dispense override \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedDispenseOverrideStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched dispense override \(code) not found")
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

    static func newBatchedDispenseOverrideCoordinator(_ store: any BatchedDispenseOverrideStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> BatchedDispenseOverrideCoordinator {
        return BatchedDispenseOverrideCoordinator(
            store: store,
            validator: defaultBatchedDispenseOverrideValidator(),
            clock: clock,
            journal: [],
            engine: defaultBatchedDispenseOverrideEngine(flags)
        )
    }
}
