import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves strict bed board forecasts through their life cycle and keeps a journal of what it did.
    final class StrictBedBoardForecastCoordinator {
        var store: any StrictBedBoardForecastStore
        var validator: StrictBedBoardForecastValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: StrictBedBoardForecastEngine

        init(store: any StrictBedBoardForecastStore, validator: StrictBedBoardForecastValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: StrictBedBoardForecastEngine) {
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
                throw Kit.Failure("strict bed board forecast \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictBedBoardForecastStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict bed board forecast \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictBedBoardForecastStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict bed board forecast \(code) not found")
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
                if item.expiresAt > cutoff {
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

    static func newStrictBedBoardForecastCoordinator(_ store: any StrictBedBoardForecastStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> StrictBedBoardForecastCoordinator {
        return StrictBedBoardForecastCoordinator(
            store: store,
            validator: defaultStrictBedBoardForecastValidator(),
            clock: clock,
            journal: [],
            engine: defaultStrictBedBoardForecastEngine(flags)
        )
    }
}
