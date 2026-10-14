import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves tiered task summaries through their life cycle and keeps a journal of what it did.
    final class TieredTaskSummaryWorkflow {
        var store: any TieredTaskSummaryStore
        var validator: TieredTaskSummaryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TieredTaskSummaryEngine

        init(store: any TieredTaskSummaryStore, validator: TieredTaskSummaryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TieredTaskSummaryEngine) {
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
                throw Kit.Failure("tiered task summary \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredTaskSummaryStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered task summary \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredTaskSummaryStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered task summary \(code) not found")
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
                if item.startsAt > cutoff {
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

    static func newTieredTaskSummaryWorkflow(_ store: any TieredTaskSummaryStore, clock: any Kit.Clocks.Clock) -> TieredTaskSummaryWorkflow {
        return TieredTaskSummaryWorkflow(
            store: store,
            validator: defaultTieredTaskSummaryValidator(),
            clock: clock,
            journal: [],
            engine: defaultTieredTaskSummaryEngine()
        )
    }
}
