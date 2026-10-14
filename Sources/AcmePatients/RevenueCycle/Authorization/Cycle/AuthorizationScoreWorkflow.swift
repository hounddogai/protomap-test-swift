import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves authorization scores through their life cycle and keeps a journal of what it did.
    final class AuthorizationScoreCoordinator {
        var store: any AuthorizationScoreStore
        var validator: AuthorizationScoreValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AuthorizationScoreEngine

        init(store: any AuthorizationScoreStore, validator: AuthorizationScoreValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AuthorizationScoreEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("authorization score \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AuthorizationScoreStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("authorization score \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AuthorizationScoreStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("authorization score \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newAuthorizationScoreCoordinator(_ store: any AuthorizationScoreStore, clock: any Kit.Clocks.Clock) -> AuthorizationScoreCoordinator {
        return AuthorizationScoreCoordinator(
            store: store,
            validator: defaultAuthorizationScoreValidator(),
            clock: clock,
            journal: [],
            engine: defaultAuthorizationScoreEngine()
        )
    }
}
