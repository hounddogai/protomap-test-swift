import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves alert forecasts through their life cycle and keeps a journal of what it did.
    final class AlertForecastWorkflow {
        var store: any AlertForecastStore
        var validator: AlertForecastValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any AlertForecastStore, validator: AlertForecastValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("alert forecast \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AlertForecastStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("alert forecast \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AlertForecastStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newAlertForecastWorkflow(_ store: any AlertForecastStore, clock: any Kit.Clocks.Clock) -> AlertForecastWorkflow {
        return AlertForecastWorkflow(
            store: store,
            validator: defaultAlertForecastValidator(),
            clock: clock,
            journal: []
        )
    }
}
