import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves legacy interaction manifests through their life cycle and keeps a journal of what it did.
    final class LegacyInteractionManifestManager {
        var store: any LegacyInteractionManifestStore
        var validator: LegacyInteractionManifestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LegacyInteractionManifestEngine

        init(store: any LegacyInteractionManifestStore, validator: LegacyInteractionManifestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LegacyInteractionManifestEngine) {
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
                throw Kit.Failure("legacy interaction manifest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyInteractionManifestStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy interaction manifest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyInteractionManifestStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy interaction manifest \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newLegacyInteractionManifestManager(_ store: any LegacyInteractionManifestStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> LegacyInteractionManifestManager {
        return LegacyInteractionManifestManager(
            store: store,
            validator: defaultLegacyInteractionManifestValidator(),
            clock: clock,
            journal: [],
            engine: defaultLegacyInteractionManifestEngine(flags)
        )
    }
}
