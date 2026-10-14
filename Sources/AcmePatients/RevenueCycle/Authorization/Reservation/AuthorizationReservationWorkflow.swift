import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves authorization reservations through their life cycle and keeps a journal of what it did.
    final class AuthorizationReservationCoordinator {
        var store: any AuthorizationReservationStore
        var validator: AuthorizationReservationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AuthorizationReservationEngine

        init(store: any AuthorizationReservationStore, validator: AuthorizationReservationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AuthorizationReservationEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("authorization reservation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AuthorizationReservationStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("authorization reservation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AuthorizationReservationStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("authorization reservation \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newAuthorizationReservationCoordinator(_ store: any AuthorizationReservationStore, clock: any Kit.Clocks.Clock) -> AuthorizationReservationCoordinator {
        return AuthorizationReservationCoordinator(
            store: store,
            validator: defaultAuthorizationReservationValidator(),
            clock: clock,
            journal: [],
            engine: defaultAuthorizationReservationEngine()
        )
    }
}
