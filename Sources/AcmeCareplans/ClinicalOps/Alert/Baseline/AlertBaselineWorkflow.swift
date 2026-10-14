import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves alert baselines through their life cycle and keeps a journal of what it did.
    final class AlertBaselineCoordinator {
        var store: any AlertBaselineStore
        var validator: AlertBaselineValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AlertBaselineEngine

        init(store: any AlertBaselineStore, validator: AlertBaselineValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AlertBaselineEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("alert baseline \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AlertBaselineStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("alert baseline \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AlertBaselineStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("alert baseline \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newAlertBaselineCoordinator(_ store: any AlertBaselineStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> AlertBaselineCoordinator {
        return AlertBaselineCoordinator(
            store: store,
            validator: defaultAlertBaselineValidator(),
            clock: clock,
            journal: [],
            engine: defaultAlertBaselineEngine(flags)
        )
    }
}
