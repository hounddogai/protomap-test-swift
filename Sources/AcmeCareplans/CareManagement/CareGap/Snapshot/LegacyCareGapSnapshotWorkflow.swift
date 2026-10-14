import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves legacy care gap snapshots through their life cycle and keeps a journal of what it did.
    final class LegacyCareGapSnapshotManager {
        var store: any LegacyCareGapSnapshotStore
        var validator: LegacyCareGapSnapshotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LegacyCareGapSnapshotEngine

        init(store: any LegacyCareGapSnapshotStore, validator: LegacyCareGapSnapshotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LegacyCareGapSnapshotEngine) {
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
                throw Kit.Failure("legacy care gap snapshot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyCareGapSnapshotStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy care gap snapshot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyCareGapSnapshotStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy care gap snapshot \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newLegacyCareGapSnapshotManager(_ store: any LegacyCareGapSnapshotStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> LegacyCareGapSnapshotManager {
        return LegacyCareGapSnapshotManager(
            store: store,
            validator: defaultLegacyCareGapSnapshotValidator(),
            clock: clock,
            journal: [],
            engine: defaultLegacyCareGapSnapshotEngine(flags)
        )
    }
}
