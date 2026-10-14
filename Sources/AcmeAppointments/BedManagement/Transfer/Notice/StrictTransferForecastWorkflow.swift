import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves strict transfer forecasts through their life cycle and keeps a journal of what it did.
    final class StrictTransferForecastDesk {
        var store: any StrictTransferForecastStore
        var validator: StrictTransferForecastValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: StrictTransferForecastEngine

        init(store: any StrictTransferForecastStore, validator: StrictTransferForecastValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: StrictTransferForecastEngine) {
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
                throw Kit.Failure("strict transfer forecast \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictTransferForecastStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict transfer forecast \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictTransferForecastStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict transfer forecast \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newStrictTransferForecastDesk(_ store: any StrictTransferForecastStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> StrictTransferForecastDesk {
        return StrictTransferForecastDesk(
            store: store,
            validator: defaultStrictTransferForecastValidator(),
            clock: clock,
            journal: [],
            engine: defaultStrictTransferForecastEngine(flags)
        )
    }
}
