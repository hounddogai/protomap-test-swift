import AcmePlatform
import Foundation

extension Labs {
    /// Moves fallback reference range batches through their life cycle and keeps a journal of what it did.
    final class FallbackReferenceRangeBatchWorkflow {
        var store: any FallbackReferenceRangeBatchStore
        var validator: FallbackReferenceRangeBatchValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FallbackReferenceRangeBatchEngine

        init(store: any FallbackReferenceRangeBatchStore, validator: FallbackReferenceRangeBatchValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FallbackReferenceRangeBatchEngine) {
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
                throw Kit.Failure("fallback reference range batch \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackReferenceRangeBatchStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback reference range batch \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackReferenceRangeBatchStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback reference range batch \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newFallbackReferenceRangeBatchWorkflow(_ store: any FallbackReferenceRangeBatchStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> FallbackReferenceRangeBatchWorkflow {
        return FallbackReferenceRangeBatchWorkflow(
            store: store,
            validator: defaultFallbackReferenceRangeBatchValidator(),
            clock: clock,
            journal: [],
            engine: defaultFallbackReferenceRangeBatchEngine(flags)
        )
    }
}
