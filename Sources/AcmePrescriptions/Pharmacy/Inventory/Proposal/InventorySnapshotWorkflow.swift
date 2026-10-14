import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves inventory snapshots through their life cycle and keeps a journal of what it did.
    final class InventorySnapshotWorkflow {
        var store: any InventorySnapshotStore
        var validator: InventorySnapshotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: InventorySnapshotEngine

        init(store: any InventorySnapshotStore, validator: InventorySnapshotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: InventorySnapshotEngine) {
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
                throw Kit.Failure("inventory snapshot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(InventorySnapshotStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("inventory snapshot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(InventorySnapshotStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("inventory snapshot \(code) not found")
            }
            let result = engine.run(item)
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

    static func newInventorySnapshotWorkflow(_ store: any InventorySnapshotStore, clock: any Kit.Clocks.Clock) -> InventorySnapshotWorkflow {
        return InventorySnapshotWorkflow(
            store: store,
            validator: defaultInventorySnapshotValidator(),
            clock: clock,
            journal: [],
            engine: defaultInventorySnapshotEngine()
        )
    }
}
