import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves batched dispense bundles through their life cycle and keeps a journal of what it did.
    final class BatchedDispenseBundleDesk {
        var store: any BatchedDispenseBundleStore
        var validator: BatchedDispenseBundleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BatchedDispenseBundleEngine

        init(store: any BatchedDispenseBundleStore, validator: BatchedDispenseBundleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BatchedDispenseBundleEngine) {
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
                throw Kit.Failure("batched dispense bundle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedDispenseBundleStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched dispense bundle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedDispenseBundleStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched dispense bundle \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newBatchedDispenseBundleDesk(_ store: any BatchedDispenseBundleStore, clock: any Kit.Clocks.Clock) -> BatchedDispenseBundleDesk {
        return BatchedDispenseBundleDesk(
            store: store,
            validator: defaultBatchedDispenseBundleValidator(),
            clock: clock,
            journal: [],
            engine: defaultBatchedDispenseBundleEngine()
        )
    }
}
