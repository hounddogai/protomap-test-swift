import AcmePlatform
import Foundation

extension Consent {
    /// Moves disclosure forecasts through their life cycle and keeps a journal of what it did.
    final class DisclosureForecastManager {
        var store: any DisclosureForecastStore
        var validator: DisclosureForecastValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DisclosureForecastEngine

        init(store: any DisclosureForecastStore, validator: DisclosureForecastValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DisclosureForecastEngine) {
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
                throw Kit.Failure("disclosure forecast \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DisclosureForecastStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("disclosure forecast \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DisclosureForecastStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("disclosure forecast \(code) not found")
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

    static func newDisclosureForecastManager(_ store: any DisclosureForecastStore, clock: any Kit.Clocks.Clock) -> DisclosureForecastManager {
        return DisclosureForecastManager(
            store: store,
            validator: defaultDisclosureForecastValidator(),
            clock: clock,
            journal: [],
            engine: defaultDisclosureForecastEngine()
        )
    }
}
