import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves alert reservations through their life cycle and keeps a journal of what it did.
    final class AlertReservationManager {
        var store: any AlertReservationStore
        var validator: AlertReservationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AlertReservationEngine

        init(store: any AlertReservationStore, validator: AlertReservationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AlertReservationEngine) {
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
                throw Kit.Failure("alert reservation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AlertReservationStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("alert reservation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AlertReservationStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("alert reservation \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newAlertReservationManager(_ store: any AlertReservationStore, clock: any Kit.Clocks.Clock) -> AlertReservationManager {
        return AlertReservationManager(
            store: store,
            validator: defaultAlertReservationValidator(),
            clock: clock,
            journal: [],
            engine: defaultAlertReservationEngine()
        )
    }
}
