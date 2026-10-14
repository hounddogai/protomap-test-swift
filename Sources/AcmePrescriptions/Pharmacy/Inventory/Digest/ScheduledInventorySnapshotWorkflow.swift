import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves scheduled inventory snapshots through their life cycle and keeps a journal of what it did.
    final class ScheduledInventorySnapshotService {
        var store: any ScheduledInventorySnapshotStore
        var validator: ScheduledInventorySnapshotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ScheduledInventorySnapshotEngine

        init(store: any ScheduledInventorySnapshotStore, validator: ScheduledInventorySnapshotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ScheduledInventorySnapshotEngine) {
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
                throw Kit.Failure("scheduled inventory snapshot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledInventorySnapshotStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled inventory snapshot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledInventorySnapshotStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled inventory snapshot \(code) not found")
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

    static func newScheduledInventorySnapshotService(_ store: any ScheduledInventorySnapshotStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ScheduledInventorySnapshotService {
        return ScheduledInventorySnapshotService(
            store: store,
            validator: defaultScheduledInventorySnapshotValidator(),
            clock: clock,
            journal: [],
            engine: defaultScheduledInventorySnapshotEngine(flags)
        )
    }
}
