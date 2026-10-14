import AcmePlatform
import Foundation

extension Consent {
    /// Moves revocation manifests through their life cycle and keeps a journal of what it did.
    final class RevocationManifestService {
        var store: any RevocationManifestStore
        var validator: RevocationManifestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RevocationManifestEngine

        init(store: any RevocationManifestStore, validator: RevocationManifestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RevocationManifestEngine) {
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
                throw Kit.Failure("revocation manifest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RevocationManifestStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("revocation manifest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RevocationManifestStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("revocation manifest \(code) not found")
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

    static func newRevocationManifestService(_ store: any RevocationManifestStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RevocationManifestService {
        return RevocationManifestService(
            store: store,
            validator: defaultRevocationManifestValidator(),
            clock: clock,
            journal: [],
            engine: defaultRevocationManifestEngine(flags)
        )
    }
}
