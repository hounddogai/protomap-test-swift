import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves default cleaning manifests through their life cycle and keeps a journal of what it did.
    final class DefaultCleaningManifestCoordinator {
        var store: any DefaultCleaningManifestStore
        var validator: DefaultCleaningManifestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DefaultCleaningManifestEngine

        init(store: any DefaultCleaningManifestStore, validator: DefaultCleaningManifestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DefaultCleaningManifestEngine) {
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
                throw Kit.Failure("default cleaning manifest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultCleaningManifestStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default cleaning manifest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultCleaningManifestStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("default cleaning manifest \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newDefaultCleaningManifestCoordinator(_ store: any DefaultCleaningManifestStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> DefaultCleaningManifestCoordinator {
        return DefaultCleaningManifestCoordinator(
            store: store,
            validator: defaultDefaultCleaningManifestValidator(),
            clock: clock,
            journal: [],
            engine: defaultDefaultCleaningManifestEngine(flags)
        )
    }
}
