import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves authorization checkpoints through their life cycle and keeps a journal of what it did.
    final class AuthorizationCheckpointCoordinator {
        var store: any AuthorizationCheckpointStore
        var validator: AuthorizationCheckpointValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AuthorizationCheckpointEngine

        init(store: any AuthorizationCheckpointStore, validator: AuthorizationCheckpointValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AuthorizationCheckpointEngine) {
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
                throw Kit.Failure("authorization checkpoint \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AuthorizationCheckpointStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("authorization checkpoint \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AuthorizationCheckpointStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("authorization checkpoint \(code) not found")
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

    static func newAuthorizationCheckpointCoordinator(_ store: any AuthorizationCheckpointStore, clock: any Kit.Clocks.Clock) -> AuthorizationCheckpointCoordinator {
        return AuthorizationCheckpointCoordinator(
            store: store,
            validator: defaultAuthorizationCheckpointValidator(),
            clock: clock,
            journal: [],
            engine: defaultAuthorizationCheckpointEngine()
        )
    }
}
