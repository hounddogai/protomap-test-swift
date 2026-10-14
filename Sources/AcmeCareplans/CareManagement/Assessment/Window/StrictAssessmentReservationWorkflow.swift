import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves strict assessment reservations through their life cycle and keeps a journal of what it did.
    final class StrictAssessmentReservationCoordinator {
        var store: any StrictAssessmentReservationStore
        var validator: StrictAssessmentReservationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: StrictAssessmentReservationEngine

        init(store: any StrictAssessmentReservationStore, validator: StrictAssessmentReservationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: StrictAssessmentReservationEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict assessment reservation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictAssessmentReservationStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict assessment reservation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictAssessmentReservationStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict assessment reservation \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newStrictAssessmentReservationCoordinator(_ store: any StrictAssessmentReservationStore, clock: any Kit.Clocks.Clock) -> StrictAssessmentReservationCoordinator {
        return StrictAssessmentReservationCoordinator(
            store: store,
            validator: defaultStrictAssessmentReservationValidator(),
            clock: clock,
            journal: [],
            engine: defaultStrictAssessmentReservationEngine()
        )
    }
}
