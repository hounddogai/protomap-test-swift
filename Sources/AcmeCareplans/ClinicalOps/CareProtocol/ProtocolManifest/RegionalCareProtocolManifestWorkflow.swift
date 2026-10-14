import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves regional care protocol manifests through their life cycle and keeps a journal of what it did.
    final class RegionalCareProtocolManifestManager {
        var store: any RegionalCareProtocolManifestStore
        var validator: RegionalCareProtocolManifestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RegionalCareProtocolManifestStore, validator: RegionalCareProtocolManifestValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional care protocol manifest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalCareProtocolManifestStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional care protocol manifest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalCareProtocolManifestStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
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

    static func newRegionalCareProtocolManifestManager(_ store: any RegionalCareProtocolManifestStore, clock: any Kit.Clocks.Clock) -> RegionalCareProtocolManifestManager {
        return RegionalCareProtocolManifestManager(
            store: store,
            validator: defaultRegionalCareProtocolManifestValidator(),
            clock: clock,
            journal: []
        )
    }
}
