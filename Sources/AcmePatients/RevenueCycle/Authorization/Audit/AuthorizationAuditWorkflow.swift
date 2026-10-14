import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves authorization audits through their life cycle and keeps a journal of what it did.
    final class AuthorizationAuditCoordinator {
        var store: any AuthorizationAuditStore
        var validator: AuthorizationAuditValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AuthorizationAuditEngine

        init(store: any AuthorizationAuditStore, validator: AuthorizationAuditValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AuthorizationAuditEngine) {
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
                throw Kit.Failure("authorization audit \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AuthorizationAuditStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("authorization audit \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AuthorizationAuditStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("authorization audit \(code) not found")
            }
            let result = engine.run(item)
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

    static func newAuthorizationAuditCoordinator(_ store: any AuthorizationAuditStore, clock: any Kit.Clocks.Clock) -> AuthorizationAuditCoordinator {
        return AuthorizationAuditCoordinator(
            store: store,
            validator: defaultAuthorizationAuditValidator(),
            clock: clock,
            journal: [],
            engine: defaultAuthorizationAuditEngine()
        )
    }
}
