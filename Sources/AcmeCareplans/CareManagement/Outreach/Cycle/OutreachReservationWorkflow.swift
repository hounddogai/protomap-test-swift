import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves outreach reservations through their life cycle and keeps a journal of what it did.
    final class OutreachReservationDesk {
        var store: any OutreachReservationStore
        var validator: OutreachReservationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any OutreachReservationStore, validator: OutreachReservationValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("outreach reservation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(OutreachReservationStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("outreach reservation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(OutreachReservationStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
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

    static func newOutreachReservationDesk(_ store: any OutreachReservationStore, clock: any Kit.Clocks.Clock) -> OutreachReservationDesk {
        return OutreachReservationDesk(
            store: store,
            validator: defaultOutreachReservationValidator(),
            clock: clock,
            journal: []
        )
    }
}
