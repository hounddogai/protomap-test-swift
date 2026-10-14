import AcmePlatform
import Foundation

extension Labs {
    /// Moves panel forecasts through their life cycle and keeps a journal of what it did.
    final class PanelForecastManager {
        var store: any PanelForecastStore
        var validator: PanelForecastValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PanelForecastStore, validator: PanelForecastValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("panel forecast \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PanelForecastStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("panel forecast \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PanelForecastStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
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

    static func newPanelForecastManager(_ store: any PanelForecastStore, clock: any Kit.Clocks.Clock) -> PanelForecastManager {
        return PanelForecastManager(
            store: store,
            validator: defaultPanelForecastValidator(),
            clock: clock,
            journal: []
        )
    }
}
