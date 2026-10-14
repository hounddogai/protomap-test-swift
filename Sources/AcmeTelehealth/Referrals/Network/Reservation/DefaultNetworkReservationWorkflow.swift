import AcmePlatform
import Foundation

extension Referrals {
    /// Moves default network reservations through their life cycle and keeps a journal of what it did.
    final class DefaultNetworkReservationService {
        var store: any DefaultNetworkReservationStore
        var validator: DefaultNetworkReservationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any DefaultNetworkReservationStore, validator: DefaultNetworkReservationValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("default network reservation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultNetworkReservationStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default network reservation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultNetworkReservationStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
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

    static func newDefaultNetworkReservationService(_ store: any DefaultNetworkReservationStore, clock: any Kit.Clocks.Clock) -> DefaultNetworkReservationService {
        return DefaultNetworkReservationService(
            store: store,
            validator: defaultDefaultNetworkReservationValidator(),
            clock: clock,
            journal: []
        )
    }
}
