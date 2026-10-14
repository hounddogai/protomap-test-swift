import AcmePlatform
import Foundation

extension Referrals {
    /// Moves adaptive closure forecasts through their life cycle and keeps a journal of what it did.
    final class AdaptiveClosureForecastDesk {
        var store: any AdaptiveClosureForecastStore
        var validator: AdaptiveClosureForecastValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any AdaptiveClosureForecastStore, validator: AdaptiveClosureForecastValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive closure forecast \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptiveClosureForecastStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive closure forecast \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptiveClosureForecastStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
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

    static func newAdaptiveClosureForecastDesk(_ store: any AdaptiveClosureForecastStore, clock: any Kit.Clocks.Clock) -> AdaptiveClosureForecastDesk {
        return AdaptiveClosureForecastDesk(
            store: store,
            validator: defaultAdaptiveClosureForecastValidator(),
            clock: clock,
            journal: []
        )
    }
}
