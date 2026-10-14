import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves risk score forecasts through their life cycle and keeps a journal of what it did.
    final class RiskScoreForecastCoordinator {
        var store: any RiskScoreForecastStore
        var validator: RiskScoreForecastValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RiskScoreForecastStore, validator: RiskScoreForecastValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("risk score forecast \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RiskScoreForecastStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("risk score forecast \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RiskScoreForecastStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
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

    static func newRiskScoreForecastCoordinator(_ store: any RiskScoreForecastStore, clock: any Kit.Clocks.Clock) -> RiskScoreForecastCoordinator {
        return RiskScoreForecastCoordinator(
            store: store,
            validator: defaultRiskScoreForecastValidator(),
            clock: clock,
            journal: []
        )
    }
}
