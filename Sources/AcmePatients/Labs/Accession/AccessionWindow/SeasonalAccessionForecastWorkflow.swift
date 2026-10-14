import AcmePlatform
import Foundation

extension Labs {
    /// Moves seasonal accession forecasts through their life cycle and keeps a journal of what it did.
    final class SeasonalAccessionForecastWorkflow {
        var store: any SeasonalAccessionForecastStore
        var validator: SeasonalAccessionForecastValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any SeasonalAccessionForecastStore, validator: SeasonalAccessionForecastValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal accession forecast \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalAccessionForecastStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal accession forecast \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalAccessionForecastStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newSeasonalAccessionForecastWorkflow(_ store: any SeasonalAccessionForecastStore, clock: any Kit.Clocks.Clock) -> SeasonalAccessionForecastWorkflow {
        return SeasonalAccessionForecastWorkflow(
            store: store,
            validator: defaultSeasonalAccessionForecastValidator(),
            clock: clock,
            journal: []
        )
    }
}
