import AcmePlatform
import Foundation

extension Staffing {
    /// Moves regional acuity plan reservations through their life cycle and keeps a journal of what it did.
    final class RegionalAcuityPlanReservationService {
        var store: any RegionalAcuityPlanReservationStore
        var validator: RegionalAcuityPlanReservationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RegionalAcuityPlanReservationStore, validator: RegionalAcuityPlanReservationValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional acuity plan reservation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalAcuityPlanReservationStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional acuity plan reservation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalAcuityPlanReservationStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
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

    static func newRegionalAcuityPlanReservationService(_ store: any RegionalAcuityPlanReservationStore, clock: any Kit.Clocks.Clock) -> RegionalAcuityPlanReservationService {
        return RegionalAcuityPlanReservationService(
            store: store,
            validator: defaultRegionalAcuityPlanReservationValidator(),
            clock: clock,
            journal: []
        )
    }
}
