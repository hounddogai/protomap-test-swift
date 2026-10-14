import AcmePlatform
import Foundation

extension Staffing {
    /// Moves shift snapshots through their life cycle and keeps a journal of what it did.
    final class ShiftSnapshotManager {
        var store: any ShiftSnapshotStore
        var validator: ShiftSnapshotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ShiftSnapshotEngine

        init(store: any ShiftSnapshotStore, validator: ShiftSnapshotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ShiftSnapshotEngine) {
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
                throw Kit.Failure("shift snapshot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ShiftSnapshotStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("shift snapshot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ShiftSnapshotStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("shift snapshot \(code) not found")
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

    static func newShiftSnapshotManager(_ store: any ShiftSnapshotStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ShiftSnapshotManager {
        return ShiftSnapshotManager(
            store: store,
            validator: defaultShiftSnapshotValidator(),
            clock: clock,
            journal: [],
            engine: defaultShiftSnapshotEngine(flags)
        )
    }
}
