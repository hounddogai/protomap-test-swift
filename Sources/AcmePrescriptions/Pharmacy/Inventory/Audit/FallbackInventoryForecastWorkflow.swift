import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves fallback inventory forecasts through their life cycle and keeps a journal of what it did.
    final class FallbackInventoryForecastWorkflow {
        var store: any FallbackInventoryForecastStore
        var validator: FallbackInventoryForecastValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any FallbackInventoryForecastStore, validator: FallbackInventoryForecastValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("fallback inventory forecast \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackInventoryForecastStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback inventory forecast \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackInventoryForecastStatus.cancelled)
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

    static func newFallbackInventoryForecastWorkflow(_ store: any FallbackInventoryForecastStore, clock: any Kit.Clocks.Clock) -> FallbackInventoryForecastWorkflow {
        return FallbackInventoryForecastWorkflow(
            store: store,
            validator: defaultFallbackInventoryForecastValidator(),
            clock: clock,
            journal: []
        )
    }
}
