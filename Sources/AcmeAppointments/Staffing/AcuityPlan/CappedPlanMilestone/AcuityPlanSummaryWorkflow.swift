import AcmePlatform
import Foundation

extension Staffing {
    /// Moves acuity plan summaries through their life cycle and keeps a journal of what it did.
    final class AcuityPlanSummaryDesk {
        var store: any AcuityPlanSummaryStore
        var validator: AcuityPlanSummaryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AcuityPlanSummaryEngine

        init(store: any AcuityPlanSummaryStore, validator: AcuityPlanSummaryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AcuityPlanSummaryEngine) {
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
                throw Kit.Failure("acuity plan summary \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AcuityPlanSummaryStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("acuity plan summary \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AcuityPlanSummaryStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("acuity plan summary \(code) not found")
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

    static func newAcuityPlanSummaryDesk(_ store: any AcuityPlanSummaryStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> AcuityPlanSummaryDesk {
        return AcuityPlanSummaryDesk(
            store: store,
            validator: defaultAcuityPlanSummaryValidator(),
            clock: clock,
            journal: [],
            engine: defaultAcuityPlanSummaryEngine(flags)
        )
    }
}
