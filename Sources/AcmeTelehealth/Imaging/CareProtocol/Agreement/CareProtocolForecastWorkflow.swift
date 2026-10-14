import AcmePlatform
import Foundation

extension Imaging {
    /// Moves care protocol forecasts through their life cycle and keeps a journal of what it did.
    final class CareProtocolForecastDesk {
        var store: any CareProtocolForecastStore
        var validator: CareProtocolForecastValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CareProtocolForecastStore, validator: CareProtocolForecastValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care protocol forecast \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CareProtocolForecastStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care protocol forecast \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CareProtocolForecastStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newCareProtocolForecastDesk(_ store: any CareProtocolForecastStore, clock: any Kit.Clocks.Clock) -> CareProtocolForecastDesk {
        return CareProtocolForecastDesk(
            store: store,
            validator: defaultCareProtocolForecastValidator(),
            clock: clock,
            journal: []
        )
    }
}
