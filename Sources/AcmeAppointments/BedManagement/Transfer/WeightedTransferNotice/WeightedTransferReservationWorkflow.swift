import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves weighted transfer reservations through their life cycle and keeps a journal of what it did.
    final class WeightedTransferReservationManager {
        var store: any WeightedTransferReservationStore
        var validator: WeightedTransferReservationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any WeightedTransferReservationStore, validator: WeightedTransferReservationValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted transfer reservation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedTransferReservationStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted transfer reservation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedTransferReservationStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
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

    static func newWeightedTransferReservationManager(_ store: any WeightedTransferReservationStore, clock: any Kit.Clocks.Clock) -> WeightedTransferReservationManager {
        return WeightedTransferReservationManager(
            store: store,
            validator: defaultWeightedTransferReservationValidator(),
            clock: clock,
            journal: []
        )
    }
}
