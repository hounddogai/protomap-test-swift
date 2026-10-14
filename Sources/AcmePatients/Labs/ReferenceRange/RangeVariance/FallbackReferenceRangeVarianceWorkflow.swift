import AcmePlatform
import Foundation

extension Labs {
    /// Moves fallback reference range variances through their life cycle and keeps a journal of what it did.
    final class FallbackReferenceRangeVarianceDesk {
        var store: any FallbackReferenceRangeVarianceStore
        var validator: FallbackReferenceRangeVarianceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FallbackReferenceRangeVarianceEngine

        init(store: any FallbackReferenceRangeVarianceStore, validator: FallbackReferenceRangeVarianceValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FallbackReferenceRangeVarianceEngine) {
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
                throw Kit.Failure("fallback reference range variance \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackReferenceRangeVarianceStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback reference range variance \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackReferenceRangeVarianceStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback reference range variance \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newFallbackReferenceRangeVarianceDesk(_ store: any FallbackReferenceRangeVarianceStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> FallbackReferenceRangeVarianceDesk {
        return FallbackReferenceRangeVarianceDesk(
            store: store,
            validator: defaultFallbackReferenceRangeVarianceValidator(),
            clock: clock,
            journal: [],
            engine: defaultFallbackReferenceRangeVarianceEngine(flags)
        )
    }
}
