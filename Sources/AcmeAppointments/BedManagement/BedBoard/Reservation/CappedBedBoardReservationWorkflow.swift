import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves capped bed board reservations through their life cycle and keeps a journal of what it did.
    final class CappedBedBoardReservationManager {
        var store: any CappedBedBoardReservationStore
        var validator: CappedBedBoardReservationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CappedBedBoardReservationEngine

        init(store: any CappedBedBoardReservationStore, validator: CappedBedBoardReservationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CappedBedBoardReservationEngine) {
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
                throw Kit.Failure("capped bed board reservation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedBedBoardReservationStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped bed board reservation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedBedBoardReservationStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped bed board reservation \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newCappedBedBoardReservationManager(_ store: any CappedBedBoardReservationStore, clock: any Kit.Clocks.Clock) -> CappedBedBoardReservationManager {
        return CappedBedBoardReservationManager(
            store: store,
            validator: defaultCappedBedBoardReservationValidator(),
            clock: clock,
            journal: [],
            engine: defaultCappedBedBoardReservationEngine()
        )
    }
}
