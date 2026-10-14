import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves recall batches through their life cycle and keeps a journal of what it did.
    final class RecallBatchWorkflow {
        var store: any RecallBatchStore
        var validator: RecallBatchValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RecallBatchEngine

        init(store: any RecallBatchStore, validator: RecallBatchValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RecallBatchEngine) {
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
                throw Kit.Failure("recall batch \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RecallBatchStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("recall batch \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RecallBatchStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("recall batch \(code) not found")
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

    static func newRecallBatchWorkflow(_ store: any RecallBatchStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RecallBatchWorkflow {
        return RecallBatchWorkflow(
            store: store,
            validator: defaultRecallBatchValidator(),
            clock: clock,
            journal: [],
            engine: defaultRecallBatchEngine(flags)
        )
    }
}
