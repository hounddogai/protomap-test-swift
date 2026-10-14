import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves seasonal denial forecasts through their life cycle and keeps a journal of what it did.
    final class SeasonalDenialForecastDesk {
        var store: any SeasonalDenialForecastStore
        var validator: SeasonalDenialForecastValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SeasonalDenialForecastEngine

        init(store: any SeasonalDenialForecastStore, validator: SeasonalDenialForecastValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SeasonalDenialForecastEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal denial forecast \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalDenialForecastStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal denial forecast \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalDenialForecastStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal denial forecast \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newSeasonalDenialForecastDesk(_ store: any SeasonalDenialForecastStore, clock: any Kit.Clocks.Clock) -> SeasonalDenialForecastDesk {
        return SeasonalDenialForecastDesk(
            store: store,
            validator: defaultSeasonalDenialForecastValidator(),
            clock: clock,
            journal: [],
            engine: defaultSeasonalDenialForecastEngine()
        )
    }
}
