import AcmePlatform
import Foundation

extension Referrals {
    /// Moves tiered follow up reservations through their life cycle and keeps a journal of what it did.
    final class TieredFollowUpReservationDesk {
        var store: any TieredFollowUpReservationStore
        var validator: TieredFollowUpReservationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any TieredFollowUpReservationStore, validator: TieredFollowUpReservationValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("tiered follow up reservation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredFollowUpReservationStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered follow up reservation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredFollowUpReservationStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newTieredFollowUpReservationDesk(_ store: any TieredFollowUpReservationStore, clock: any Kit.Clocks.Clock) -> TieredFollowUpReservationDesk {
        return TieredFollowUpReservationDesk(
            store: store,
            validator: defaultTieredFollowUpReservationValidator(),
            clock: clock,
            journal: []
        )
    }
}
