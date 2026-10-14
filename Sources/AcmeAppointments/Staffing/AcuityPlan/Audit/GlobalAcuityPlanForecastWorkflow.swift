import AcmePlatform
import Foundation

extension Staffing {
    /// Moves global acuity plan forecasts through their life cycle and keeps a journal of what it did.
    final class GlobalAcuityPlanForecastCoordinator {
        var store: any GlobalAcuityPlanForecastStore
        var validator: GlobalAcuityPlanForecastValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GlobalAcuityPlanForecastEngine

        init(store: any GlobalAcuityPlanForecastStore, validator: GlobalAcuityPlanForecastValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GlobalAcuityPlanForecastEngine) {
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
                throw Kit.Failure("global acuity plan forecast \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalAcuityPlanForecastStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global acuity plan forecast \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalAcuityPlanForecastStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("global acuity plan forecast \(code) not found")
            }
            let result = engine.price(item)
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

    static func newGlobalAcuityPlanForecastCoordinator(_ store: any GlobalAcuityPlanForecastStore, clock: any Kit.Clocks.Clock) -> GlobalAcuityPlanForecastCoordinator {
        return GlobalAcuityPlanForecastCoordinator(
            store: store,
            validator: defaultGlobalAcuityPlanForecastValidator(),
            clock: clock,
            journal: [],
            engine: defaultGlobalAcuityPlanForecastEngine()
        )
    }
}
