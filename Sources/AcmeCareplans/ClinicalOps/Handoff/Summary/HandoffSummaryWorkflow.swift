import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves handoff summaries through their life cycle and keeps a journal of what it did.
    final class HandoffSummaryWorkflow {
        var store: any HandoffSummaryStore
        var validator: HandoffSummaryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: HandoffSummaryEngine

        init(store: any HandoffSummaryStore, validator: HandoffSummaryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: HandoffSummaryEngine) {
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
                throw Kit.Failure("handoff summary \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(HandoffSummaryStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("handoff summary \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(HandoffSummaryStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("handoff summary \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newHandoffSummaryWorkflow(_ store: any HandoffSummaryStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> HandoffSummaryWorkflow {
        return HandoffSummaryWorkflow(
            store: store,
            validator: defaultHandoffSummaryValidator(),
            clock: clock,
            journal: [],
            engine: defaultHandoffSummaryEngine(flags)
        )
    }
}
