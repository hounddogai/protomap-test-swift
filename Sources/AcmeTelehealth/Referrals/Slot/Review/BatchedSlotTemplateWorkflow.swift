import AcmePlatform
import Foundation

extension Referrals {
    /// Moves batched slot templates through their life cycle and keeps a journal of what it did.
    final class BatchedSlotTemplateDesk {
        var store: any BatchedSlotTemplateStore
        var validator: BatchedSlotTemplateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BatchedSlotTemplateEngine

        init(store: any BatchedSlotTemplateStore, validator: BatchedSlotTemplateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BatchedSlotTemplateEngine) {
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
                throw Kit.Failure("batched slot template \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedSlotTemplateStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched slot template \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedSlotTemplateStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched slot template \(code) not found")
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

    static func newBatchedSlotTemplateDesk(_ store: any BatchedSlotTemplateStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> BatchedSlotTemplateDesk {
        return BatchedSlotTemplateDesk(
            store: store,
            validator: defaultBatchedSlotTemplateValidator(),
            clock: clock,
            journal: [],
            engine: defaultBatchedSlotTemplateEngine(flags)
        )
    }
}
