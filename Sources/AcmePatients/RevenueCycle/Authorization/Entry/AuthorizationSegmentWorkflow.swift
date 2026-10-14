import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves authorization segments through their life cycle and keeps a journal of what it did.
    final class AuthorizationSegmentWorkflow {
        var store: any AuthorizationSegmentStore
        var validator: AuthorizationSegmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AuthorizationSegmentEngine

        init(store: any AuthorizationSegmentStore, validator: AuthorizationSegmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AuthorizationSegmentEngine) {
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
                throw Kit.Failure("authorization segment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AuthorizationSegmentStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("authorization segment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AuthorizationSegmentStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("authorization segment \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newAuthorizationSegmentWorkflow(_ store: any AuthorizationSegmentStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> AuthorizationSegmentWorkflow {
        return AuthorizationSegmentWorkflow(
            store: store,
            validator: defaultAuthorizationSegmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultAuthorizationSegmentEngine(flags)
        )
    }
}
