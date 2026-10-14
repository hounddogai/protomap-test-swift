import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves remittance reservations through their life cycle and keeps a journal of what it did.
    final class RemittanceReservationDesk {
        var store: any RemittanceReservationStore
        var validator: RemittanceReservationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RemittanceReservationStore, validator: RemittanceReservationValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("remittance reservation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RemittanceReservationStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("remittance reservation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RemittanceReservationStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
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

    static func newRemittanceReservationDesk(_ store: any RemittanceReservationStore, clock: any Kit.Clocks.Clock) -> RemittanceReservationDesk {
        return RemittanceReservationDesk(
            store: store,
            validator: defaultRemittanceReservationValidator(),
            clock: clock,
            journal: []
        )
    }
}
