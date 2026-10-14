import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves authorization manifests through their life cycle and keeps a journal of what it did.
    final class AuthorizationManifestCoordinator {
        var store: any AuthorizationManifestStore
        var validator: AuthorizationManifestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AuthorizationManifestEngine

        init(store: any AuthorizationManifestStore, validator: AuthorizationManifestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AuthorizationManifestEngine) {
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
                throw Kit.Failure("authorization manifest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AuthorizationManifestStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("authorization manifest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AuthorizationManifestStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("authorization manifest \(code) not found")
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

    static func newAuthorizationManifestCoordinator(_ store: any AuthorizationManifestStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> AuthorizationManifestCoordinator {
        return AuthorizationManifestCoordinator(
            store: store,
            validator: defaultAuthorizationManifestValidator(),
            clock: clock,
            journal: [],
            engine: defaultAuthorizationManifestEngine(flags)
        )
    }
}
