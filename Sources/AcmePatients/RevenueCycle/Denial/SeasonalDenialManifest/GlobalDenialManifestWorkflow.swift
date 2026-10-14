import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves global denial manifests through their life cycle and keeps a journal of what it did.
    final class GlobalDenialManifestCoordinator {
        var store: any GlobalDenialManifestStore
        var validator: GlobalDenialManifestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GlobalDenialManifestEngine

        init(store: any GlobalDenialManifestStore, validator: GlobalDenialManifestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GlobalDenialManifestEngine) {
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
                throw Kit.Failure("global denial manifest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalDenialManifestStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global denial manifest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalDenialManifestStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("global denial manifest \(code) not found")
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

    static func newGlobalDenialManifestCoordinator(_ store: any GlobalDenialManifestStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> GlobalDenialManifestCoordinator {
        return GlobalDenialManifestCoordinator(
            store: store,
            validator: defaultGlobalDenialManifestValidator(),
            clock: clock,
            journal: [],
            engine: defaultGlobalDenialManifestEngine(flags)
        )
    }
}
