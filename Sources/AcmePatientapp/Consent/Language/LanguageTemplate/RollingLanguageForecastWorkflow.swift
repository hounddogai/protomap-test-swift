import AcmePlatform
import Foundation

extension Consent {
    /// Moves rolling language forecasts through their life cycle and keeps a journal of what it did.
    final class RollingLanguageForecastWorkflow {
        var store: any RollingLanguageForecastStore
        var validator: RollingLanguageForecastValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RollingLanguageForecastStore, validator: RollingLanguageForecastValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("rolling language forecast \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingLanguageForecastStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling language forecast \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingLanguageForecastStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newRollingLanguageForecastWorkflow(_ store: any RollingLanguageForecastStore, clock: any Kit.Clocks.Clock) -> RollingLanguageForecastWorkflow {
        return RollingLanguageForecastWorkflow(
            store: store,
            validator: defaultRollingLanguageForecastValidator(),
            clock: clock,
            journal: []
        )
    }
}
