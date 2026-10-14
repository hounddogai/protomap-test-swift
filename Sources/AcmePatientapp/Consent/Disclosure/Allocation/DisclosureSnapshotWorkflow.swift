import AcmePlatform
import Foundation

extension Consent {
    /// Moves disclosure snapshots through their life cycle and keeps a journal of what it did.
    final class DisclosureSnapshotCoordinator {
        var store: any DisclosureSnapshotStore
        var validator: DisclosureSnapshotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DisclosureSnapshotEngine

        init(store: any DisclosureSnapshotStore, validator: DisclosureSnapshotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DisclosureSnapshotEngine) {
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
                throw Kit.Failure("disclosure snapshot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DisclosureSnapshotStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("disclosure snapshot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DisclosureSnapshotStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("disclosure snapshot \(code) not found")
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

    static func newDisclosureSnapshotCoordinator(_ store: any DisclosureSnapshotStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> DisclosureSnapshotCoordinator {
        return DisclosureSnapshotCoordinator(
            store: store,
            validator: defaultDisclosureSnapshotValidator(),
            clock: clock,
            journal: [],
            engine: defaultDisclosureSnapshotEngine(flags)
        )
    }
}
