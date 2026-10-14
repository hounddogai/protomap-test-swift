import AcmePlatform
import Foundation

extension Labs {
    /// Moves default specimen reservations through their life cycle and keeps a journal of what it did.
    final class DefaultSpecimenReservationCoordinator {
        var store: any DefaultSpecimenReservationStore
        var validator: DefaultSpecimenReservationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any DefaultSpecimenReservationStore, validator: DefaultSpecimenReservationValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default specimen reservation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultSpecimenReservationStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default specimen reservation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultSpecimenReservationStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
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

    static func newDefaultSpecimenReservationCoordinator(_ store: any DefaultSpecimenReservationStore, clock: any Kit.Clocks.Clock) -> DefaultSpecimenReservationCoordinator {
        return DefaultSpecimenReservationCoordinator(
            store: store,
            validator: defaultDefaultSpecimenReservationValidator(),
            clock: clock,
            journal: []
        )
    }
}
