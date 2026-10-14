import AcmePlatform
import Foundation

extension Staffing {
    /// Moves credential reservations through their life cycle and keeps a journal of what it did.
    final class CredentialReservationService {
        var store: any CredentialReservationStore
        var validator: CredentialReservationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CredentialReservationEngine

        init(store: any CredentialReservationStore, validator: CredentialReservationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CredentialReservationEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("credential reservation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CredentialReservationStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("credential reservation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CredentialReservationStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("credential reservation \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newCredentialReservationService(_ store: any CredentialReservationStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CredentialReservationService {
        return CredentialReservationService(
            store: store,
            validator: defaultCredentialReservationValidator(),
            clock: clock,
            journal: [],
            engine: defaultCredentialReservationEngine(flags)
        )
    }
}
