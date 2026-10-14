import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves scheduled discharge plan forecasts through their life cycle and keeps a journal of what it did.
    final class ScheduledDischargePlanForecastDesk {
        var store: any ScheduledDischargePlanForecastStore
        var validator: ScheduledDischargePlanForecastValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ScheduledDischargePlanForecastEngine

        init(store: any ScheduledDischargePlanForecastStore, validator: ScheduledDischargePlanForecastValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ScheduledDischargePlanForecastEngine) {
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
                throw Kit.Failure("scheduled discharge plan forecast \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledDischargePlanForecastStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled discharge plan forecast \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledDischargePlanForecastStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled discharge plan forecast \(code) not found")
            }
            let result = engine.run(item)
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

    static func newScheduledDischargePlanForecastDesk(_ store: any ScheduledDischargePlanForecastStore, clock: any Kit.Clocks.Clock) -> ScheduledDischargePlanForecastDesk {
        return ScheduledDischargePlanForecastDesk(
            store: store,
            validator: defaultScheduledDischargePlanForecastValidator(),
            clock: clock,
            journal: [],
            engine: defaultScheduledDischargePlanForecastEngine()
        )
    }
}
