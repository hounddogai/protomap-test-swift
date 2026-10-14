import AcmePlatform
import Foundation

extension Labs {
    /// Moves specimen forecasts through their life cycle and keeps a journal of what it did.
    final class SpecimenForecastDesk {
        var store: any SpecimenForecastStore
        var validator: SpecimenForecastValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any SpecimenForecastStore, validator: SpecimenForecastValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("specimen forecast \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SpecimenForecastStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("specimen forecast \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SpecimenForecastStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newSpecimenForecastDesk(_ store: any SpecimenForecastStore, clock: any Kit.Clocks.Clock) -> SpecimenForecastDesk {
        return SpecimenForecastDesk(
            store: store,
            validator: defaultSpecimenForecastValidator(),
            clock: clock,
            journal: []
        )
    }
}
