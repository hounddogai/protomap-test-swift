import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves dispense reservations through their life cycle and keeps a journal of what it did.
    final class DispenseReservationWorkflow {
        var store: any DispenseReservationStore
        var validator: DispenseReservationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DispenseReservationEngine

        init(store: any DispenseReservationStore, validator: DispenseReservationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DispenseReservationEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("dispense reservation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DispenseReservationStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("dispense reservation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DispenseReservationStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("dispense reservation \(code) not found")
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

    static func newDispenseReservationWorkflow(_ store: any DispenseReservationStore, clock: any Kit.Clocks.Clock) -> DispenseReservationWorkflow {
        return DispenseReservationWorkflow(
            store: store,
            validator: defaultDispenseReservationValidator(),
            clock: clock,
            journal: [],
            engine: defaultDispenseReservationEngine()
        )
    }
}
