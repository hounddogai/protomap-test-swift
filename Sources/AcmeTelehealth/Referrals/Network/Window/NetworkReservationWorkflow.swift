import AcmePlatform
import Foundation

extension Referrals {
    /// Moves network reservations through their life cycle and keeps a journal of what it did.
    final class NetworkReservationDesk {
        var store: any NetworkReservationStore
        var validator: NetworkReservationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: NetworkReservationEngine

        init(store: any NetworkReservationStore, validator: NetworkReservationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: NetworkReservationEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("network reservation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(NetworkReservationStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("network reservation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(NetworkReservationStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("network reservation \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newNetworkReservationDesk(_ store: any NetworkReservationStore, clock: any Kit.Clocks.Clock) -> NetworkReservationDesk {
        return NetworkReservationDesk(
            store: store,
            validator: defaultNetworkReservationValidator(),
            clock: clock,
            journal: [],
            engine: defaultNetworkReservationEngine()
        )
    }
}
