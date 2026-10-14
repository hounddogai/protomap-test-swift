import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves tiered goal forecasts through their life cycle and keeps a journal of what it did.
    final class TieredGoalForecastDesk {
        var store: any TieredGoalForecastStore
        var validator: TieredGoalForecastValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TieredGoalForecastEngine

        init(store: any TieredGoalForecastStore, validator: TieredGoalForecastValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TieredGoalForecastEngine) {
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
                throw Kit.Failure("tiered goal forecast \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredGoalForecastStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered goal forecast \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredGoalForecastStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered goal forecast \(code) not found")
            }
            let result = engine.run(item)
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

    static func newTieredGoalForecastDesk(_ store: any TieredGoalForecastStore, clock: any Kit.Clocks.Clock) -> TieredGoalForecastDesk {
        return TieredGoalForecastDesk(
            store: store,
            validator: defaultTieredGoalForecastValidator(),
            clock: clock,
            journal: [],
            engine: defaultTieredGoalForecastEngine()
        )
    }
}
