import AcmePlatform
import Foundation

extension Referrals {
    /// Moves eligibility summaries through their life cycle and keeps a journal of what it did.
    final class EligibilitySummaryDesk {
        var store: any EligibilitySummaryStore
        var validator: EligibilitySummaryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: EligibilitySummaryEngine

        init(store: any EligibilitySummaryStore, validator: EligibilitySummaryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: EligibilitySummaryEngine) {
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
                throw Kit.Failure("eligibility summary \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(EligibilitySummaryStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("eligibility summary \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(EligibilitySummaryStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("eligibility summary \(code) not found")
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

    static func newEligibilitySummaryDesk(_ store: any EligibilitySummaryStore, clock: any Kit.Clocks.Clock) -> EligibilitySummaryDesk {
        return EligibilitySummaryDesk(
            store: store,
            validator: defaultEligibilitySummaryValidator(),
            clock: clock,
            journal: [],
            engine: defaultEligibilitySummaryEngine()
        )
    }
}
