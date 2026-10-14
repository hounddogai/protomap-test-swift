import AcmePlatform
import Foundation

extension Consent {
    /// Moves regional proxy forecasts through their life cycle and keeps a journal of what it did.
    final class RegionalProxyForecastCoordinator {
        var store: any RegionalProxyForecastStore
        var validator: RegionalProxyForecastValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RegionalProxyForecastStore, validator: RegionalProxyForecastValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("regional proxy forecast \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalProxyForecastStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional proxy forecast \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalProxyForecastStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
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

    static func newRegionalProxyForecastCoordinator(_ store: any RegionalProxyForecastStore, clock: any Kit.Clocks.Clock) -> RegionalProxyForecastCoordinator {
        return RegionalProxyForecastCoordinator(
            store: store,
            validator: defaultRegionalProxyForecastValidator(),
            clock: clock,
            journal: []
        )
    }
}
