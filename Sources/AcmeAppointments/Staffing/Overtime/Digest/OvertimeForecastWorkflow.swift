import AcmePlatform
import Foundation

extension Staffing {
    /// Moves overtime forecasts through their life cycle and keeps a journal of what it did.
    final class OvertimeForecastWorkflow {
        var store: any OvertimeForecastStore
        var validator: OvertimeForecastValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: OvertimeForecastEngine

        init(store: any OvertimeForecastStore, validator: OvertimeForecastValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: OvertimeForecastEngine) {
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
                throw Kit.Failure("overtime forecast \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(OvertimeForecastStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("overtime forecast \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(OvertimeForecastStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("overtime forecast \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newOvertimeForecastWorkflow(_ store: any OvertimeForecastStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> OvertimeForecastWorkflow {
        return OvertimeForecastWorkflow(
            store: store,
            validator: defaultOvertimeForecastValidator(),
            clock: clock,
            journal: [],
            engine: defaultOvertimeForecastEngine(flags)
        )
    }
}
