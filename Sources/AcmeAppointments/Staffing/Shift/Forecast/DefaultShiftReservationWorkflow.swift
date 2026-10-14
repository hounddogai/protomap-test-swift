import AcmePlatform
import Foundation

extension Staffing {
    /// Moves default shift reservations through their life cycle and keeps a journal of what it did.
    final class DefaultShiftReservationDesk {
        var store: any DefaultShiftReservationStore
        var validator: DefaultShiftReservationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any DefaultShiftReservationStore, validator: DefaultShiftReservationValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("default shift reservation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultShiftReservationStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default shift reservation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultShiftReservationStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
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

    static func newDefaultShiftReservationDesk(_ store: any DefaultShiftReservationStore, clock: any Kit.Clocks.Clock) -> DefaultShiftReservationDesk {
        return DefaultShiftReservationDesk(
            store: store,
            validator: defaultDefaultShiftReservationValidator(),
            clock: clock,
            journal: []
        )
    }
}
