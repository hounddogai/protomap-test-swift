import AcmePlatform
import Foundation

extension Labs {
    /// Moves accession manifests through their life cycle and keeps a journal of what it did.
    final class AccessionManifestManager {
        var store: any AccessionManifestStore
        var validator: AccessionManifestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AccessionManifestEngine

        init(store: any AccessionManifestStore, validator: AccessionManifestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AccessionManifestEngine) {
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
                throw Kit.Failure("accession manifest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AccessionManifestStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("accession manifest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AccessionManifestStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("accession manifest \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newAccessionManifestManager(_ store: any AccessionManifestStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> AccessionManifestManager {
        return AccessionManifestManager(
            store: store,
            validator: defaultAccessionManifestValidator(),
            clock: clock,
            journal: [],
            engine: defaultAccessionManifestEngine(flags)
        )
    }
}
