import AcmePlatform
import Foundation

extension Staffing {
    /// Moves manual acuity plan reservations through their life cycle and keeps a journal of what it did.
    final class ManualAcuityPlanReservationDesk {
        var store: any ManualAcuityPlanReservationStore
        var validator: ManualAcuityPlanReservationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ManualAcuityPlanReservationStore, validator: ManualAcuityPlanReservationValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("manual acuity plan reservation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualAcuityPlanReservationStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual acuity plan reservation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualAcuityPlanReservationStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newManualAcuityPlanReservationDesk(_ store: any ManualAcuityPlanReservationStore, clock: any Kit.Clocks.Clock) -> ManualAcuityPlanReservationDesk {
        return ManualAcuityPlanReservationDesk(
            store: store,
            validator: defaultManualAcuityPlanReservationValidator(),
            clock: clock,
            journal: []
        )
    }
}
