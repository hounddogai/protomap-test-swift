import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves primary bed board reservations through their life cycle and keeps a journal of what it did.
    final class PrimaryBedBoardReservationCoordinator {
        var store: any PrimaryBedBoardReservationStore
        var validator: PrimaryBedBoardReservationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrimaryBedBoardReservationEngine

        init(store: any PrimaryBedBoardReservationStore, validator: PrimaryBedBoardReservationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrimaryBedBoardReservationEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary bed board reservation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryBedBoardReservationStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary bed board reservation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryBedBoardReservationStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary bed board reservation \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newPrimaryBedBoardReservationCoordinator(_ store: any PrimaryBedBoardReservationStore, clock: any Kit.Clocks.Clock) -> PrimaryBedBoardReservationCoordinator {
        return PrimaryBedBoardReservationCoordinator(
            store: store,
            validator: defaultPrimaryBedBoardReservationValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrimaryBedBoardReservationEngine()
        )
    }
}
