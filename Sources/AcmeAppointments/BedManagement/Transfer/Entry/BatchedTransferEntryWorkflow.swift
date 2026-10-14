import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves batched transfer entries through their life cycle and keeps a journal of what it did.
    final class BatchedTransferEntryWorkflow {
        var store: any BatchedTransferEntryStore
        var validator: BatchedTransferEntryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BatchedTransferEntryEngine

        init(store: any BatchedTransferEntryStore, validator: BatchedTransferEntryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BatchedTransferEntryEngine) {
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
                throw Kit.Failure("batched transfer entry \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedTransferEntryStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched transfer entry \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedTransferEntryStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched transfer entry \(code) not found")
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

    static func newBatchedTransferEntryWorkflow(_ store: any BatchedTransferEntryStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> BatchedTransferEntryWorkflow {
        return BatchedTransferEntryWorkflow(
            store: store,
            validator: defaultBatchedTransferEntryValidator(),
            clock: clock,
            journal: [],
            engine: defaultBatchedTransferEntryEngine(flags)
        )
    }
}
