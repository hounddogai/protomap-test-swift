import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves authorization variances through their life cycle and keeps a journal of what it did.
    final class AuthorizationVarianceManager {
        var store: any AuthorizationVarianceStore
        var validator: AuthorizationVarianceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any AuthorizationVarianceStore, validator: AuthorizationVarianceValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("authorization variance \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AuthorizationVarianceStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("authorization variance \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AuthorizationVarianceStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newAuthorizationVarianceManager(_ store: any AuthorizationVarianceStore, clock: any Kit.Clocks.Clock) -> AuthorizationVarianceManager {
        return AuthorizationVarianceManager(
            store: store,
            validator: defaultAuthorizationVarianceValidator(),
            clock: clock,
            journal: []
        )
    }
}
