import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves authorization plans through their life cycle and keeps a journal of what it did.
    final class AuthorizationPlanService {
        var store: any AuthorizationPlanStore
        var validator: AuthorizationPlanValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AuthorizationPlanEngine

        init(store: any AuthorizationPlanStore, validator: AuthorizationPlanValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AuthorizationPlanEngine) {
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
                throw Kit.Failure("authorization plan \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AuthorizationPlanStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("authorization plan \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AuthorizationPlanStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("authorization plan \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newAuthorizationPlanService(_ store: any AuthorizationPlanStore, clock: any Kit.Clocks.Clock) -> AuthorizationPlanService {
        return AuthorizationPlanService(
            store: store,
            validator: defaultAuthorizationPlanValidator(),
            clock: clock,
            journal: [],
            engine: defaultAuthorizationPlanEngine()
        )
    }
}
