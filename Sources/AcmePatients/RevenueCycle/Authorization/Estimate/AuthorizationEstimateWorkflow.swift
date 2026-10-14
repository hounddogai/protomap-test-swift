import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves authorization estimates through their life cycle and keeps a journal of what it did.
    final class AuthorizationEstimateCoordinator {
        var store: any AuthorizationEstimateStore
        var validator: AuthorizationEstimateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AuthorizationEstimateEngine

        init(store: any AuthorizationEstimateStore, validator: AuthorizationEstimateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AuthorizationEstimateEngine) {
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
                throw Kit.Failure("authorization estimate \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AuthorizationEstimateStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("authorization estimate \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AuthorizationEstimateStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("authorization estimate \(code) not found")
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

    static func newAuthorizationEstimateCoordinator(_ store: any AuthorizationEstimateStore, clock: any Kit.Clocks.Clock) -> AuthorizationEstimateCoordinator {
        return AuthorizationEstimateCoordinator(
            store: store,
            validator: defaultAuthorizationEstimateValidator(),
            clock: clock,
            journal: [],
            engine: defaultAuthorizationEstimateEngine()
        )
    }
}
