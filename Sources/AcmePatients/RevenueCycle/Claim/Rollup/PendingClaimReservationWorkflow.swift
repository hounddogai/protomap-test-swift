import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves pending claim reservations through their life cycle and keeps a journal of what it did.
    final class PendingClaimReservationService {
        var store: any PendingClaimReservationStore
        var validator: PendingClaimReservationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PendingClaimReservationStore, validator: PendingClaimReservationValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("pending claim reservation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingClaimReservationStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending claim reservation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingClaimReservationStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
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

    static func newPendingClaimReservationService(_ store: any PendingClaimReservationStore, clock: any Kit.Clocks.Clock) -> PendingClaimReservationService {
        return PendingClaimReservationService(
            store: store,
            validator: defaultPendingClaimReservationValidator(),
            clock: clock,
            journal: []
        )
    }
}
