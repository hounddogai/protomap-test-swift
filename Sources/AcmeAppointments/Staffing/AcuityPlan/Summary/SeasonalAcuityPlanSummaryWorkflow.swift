import AcmePlatform
import Foundation

extension Staffing {
    /// Moves seasonal acuity plan summaries through their life cycle and keeps a journal of what it did.
    final class SeasonalAcuityPlanSummaryDesk {
        var store: any SeasonalAcuityPlanSummaryStore
        var validator: SeasonalAcuityPlanSummaryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any SeasonalAcuityPlanSummaryStore, validator: SeasonalAcuityPlanSummaryValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal acuity plan summary \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalAcuityPlanSummaryStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal acuity plan summary \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalAcuityPlanSummaryStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
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

    static func newSeasonalAcuityPlanSummaryDesk(_ store: any SeasonalAcuityPlanSummaryStore, clock: any Kit.Clocks.Clock) -> SeasonalAcuityPlanSummaryDesk {
        return SeasonalAcuityPlanSummaryDesk(
            store: store,
            validator: defaultSeasonalAcuityPlanSummaryValidator(),
            clock: clock,
            journal: []
        )
    }
}
