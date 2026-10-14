import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves lenient care protocol manifests through their life cycle and keeps a journal of what it did.
    final class LenientCareProtocolManifestManager {
        var store: any LenientCareProtocolManifestStore
        var validator: LenientCareProtocolManifestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LenientCareProtocolManifestEngine

        init(store: any LenientCareProtocolManifestStore, validator: LenientCareProtocolManifestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LenientCareProtocolManifestEngine) {
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
                throw Kit.Failure("lenient care protocol manifest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientCareProtocolManifestStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient care protocol manifest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientCareProtocolManifestStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient care protocol manifest \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newLenientCareProtocolManifestManager(_ store: any LenientCareProtocolManifestStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> LenientCareProtocolManifestManager {
        return LenientCareProtocolManifestManager(
            store: store,
            validator: defaultLenientCareProtocolManifestValidator(),
            clock: clock,
            journal: [],
            engine: defaultLenientCareProtocolManifestEngine(flags)
        )
    }
}
