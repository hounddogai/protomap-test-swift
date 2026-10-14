import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves authorization rollups through their life cycle and keeps a journal of what it did.
    final class AuthorizationRollupManager {
        var store: any AuthorizationRollupStore
        var validator: AuthorizationRollupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AuthorizationRollupEngine

        init(store: any AuthorizationRollupStore, validator: AuthorizationRollupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AuthorizationRollupEngine) {
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
                throw Kit.Failure("authorization rollup \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AuthorizationRollupStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("authorization rollup \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AuthorizationRollupStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("authorization rollup \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newAuthorizationRollupManager(_ store: any AuthorizationRollupStore, clock: any Kit.Clocks.Clock) -> AuthorizationRollupManager {
        return AuthorizationRollupManager(
            store: store,
            validator: defaultAuthorizationRollupValidator(),
            clock: clock,
            journal: [],
            engine: defaultAuthorizationRollupEngine()
        )
    }
}
