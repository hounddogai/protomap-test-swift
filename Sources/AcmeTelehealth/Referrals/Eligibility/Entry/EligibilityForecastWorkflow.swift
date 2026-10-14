import AcmePlatform
import Foundation

extension Referrals {
    /// Moves eligibility forecasts through their life cycle and keeps a journal of what it did.
    final class EligibilityForecastManager {
        var store: any EligibilityForecastStore
        var validator: EligibilityForecastValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: EligibilityForecastEngine

        init(store: any EligibilityForecastStore, validator: EligibilityForecastValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: EligibilityForecastEngine) {
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
                throw Kit.Failure("eligibility forecast \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(EligibilityForecastStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("eligibility forecast \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(EligibilityForecastStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("eligibility forecast \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newEligibilityForecastManager(_ store: any EligibilityForecastStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> EligibilityForecastManager {
        return EligibilityForecastManager(
            store: store,
            validator: defaultEligibilityForecastValidator(),
            clock: clock,
            journal: [],
            engine: defaultEligibilityForecastEngine(flags)
        )
    }
}
