import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves strict statement forecasts through their life cycle and keeps a journal of what it did.
    final class StrictStatementForecastService {
        var store: any StrictStatementForecastStore
        var validator: StrictStatementForecastValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: StrictStatementForecastEngine

        init(store: any StrictStatementForecastStore, validator: StrictStatementForecastValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: StrictStatementForecastEngine) {
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
                throw Kit.Failure("strict statement forecast \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictStatementForecastStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict statement forecast \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictStatementForecastStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict statement forecast \(code) not found")
            }
            let result = engine.run(item)
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

    static func newStrictStatementForecastService(_ store: any StrictStatementForecastStore, clock: any Kit.Clocks.Clock) -> StrictStatementForecastService {
        return StrictStatementForecastService(
            store: store,
            validator: defaultStrictStatementForecastValidator(),
            clock: clock,
            journal: [],
            engine: defaultStrictStatementForecastEngine()
        )
    }
}
