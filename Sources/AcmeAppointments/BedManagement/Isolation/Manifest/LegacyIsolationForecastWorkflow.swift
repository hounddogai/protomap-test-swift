import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves legacy isolation forecasts through their life cycle and keeps a journal of what it did.
    final class LegacyIsolationForecastManager {
        var store: any LegacyIsolationForecastStore
        var validator: LegacyIsolationForecastValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LegacyIsolationForecastEngine

        init(store: any LegacyIsolationForecastStore, validator: LegacyIsolationForecastValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LegacyIsolationForecastEngine) {
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
                throw Kit.Failure("legacy isolation forecast \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyIsolationForecastStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy isolation forecast \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyIsolationForecastStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy isolation forecast \(code) not found")
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

    static func newLegacyIsolationForecastManager(_ store: any LegacyIsolationForecastStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> LegacyIsolationForecastManager {
        return LegacyIsolationForecastManager(
            store: store,
            validator: defaultLegacyIsolationForecastValidator(),
            clock: clock,
            journal: [],
            engine: defaultLegacyIsolationForecastEngine(flags)
        )
    }
}
