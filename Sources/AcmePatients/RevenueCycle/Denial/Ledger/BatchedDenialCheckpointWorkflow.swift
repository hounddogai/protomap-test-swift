import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves batched denial checkpoints through their life cycle and keeps a journal of what it did.
    final class BatchedDenialCheckpointManager {
        var store: any BatchedDenialCheckpointStore
        var validator: BatchedDenialCheckpointValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BatchedDenialCheckpointEngine

        init(store: any BatchedDenialCheckpointStore, validator: BatchedDenialCheckpointValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BatchedDenialCheckpointEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched denial checkpoint \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedDenialCheckpointStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched denial checkpoint \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedDenialCheckpointStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched denial checkpoint \(code) not found")
            }
            let result = engine.price(item)
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

    static func newBatchedDenialCheckpointManager(_ store: any BatchedDenialCheckpointStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> BatchedDenialCheckpointManager {
        return BatchedDenialCheckpointManager(
            store: store,
            validator: defaultBatchedDenialCheckpointValidator(),
            clock: clock,
            journal: [],
            engine: defaultBatchedDenialCheckpointEngine(flags)
        )
    }
}
