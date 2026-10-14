import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves authorization allocations through their life cycle and keeps a journal of what it did.
    final class AuthorizationAllocationWorkflow {
        var store: any AuthorizationAllocationStore
        var validator: AuthorizationAllocationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any AuthorizationAllocationStore, validator: AuthorizationAllocationValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("authorization allocation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AuthorizationAllocationStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("authorization allocation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AuthorizationAllocationStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newAuthorizationAllocationWorkflow(_ store: any AuthorizationAllocationStore, clock: any Kit.Clocks.Clock) -> AuthorizationAllocationWorkflow {
        return AuthorizationAllocationWorkflow(
            store: store,
            validator: defaultAuthorizationAllocationValidator(),
            clock: clock,
            journal: []
        )
    }
}
