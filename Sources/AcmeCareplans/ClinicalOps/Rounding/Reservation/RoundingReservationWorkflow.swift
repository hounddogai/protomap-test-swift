import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves rounding reservations through their life cycle and keeps a journal of what it did.
    final class RoundingReservationCoordinator {
        var store: any RoundingReservationStore
        var validator: RoundingReservationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RoundingReservationEngine

        init(store: any RoundingReservationStore, validator: RoundingReservationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RoundingReservationEngine) {
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
                throw Kit.Failure("rounding reservation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RoundingReservationStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rounding reservation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RoundingReservationStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("rounding reservation \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newRoundingReservationCoordinator(_ store: any RoundingReservationStore, clock: any Kit.Clocks.Clock) -> RoundingReservationCoordinator {
        return RoundingReservationCoordinator(
            store: store,
            validator: defaultRoundingReservationValidator(),
            clock: clock,
            journal: [],
            engine: defaultRoundingReservationEngine()
        )
    }
}
