import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves primary inventory snapshots through their life cycle and keeps a journal of what it did.
    final class PrimaryInventorySnapshotWorkflow {
        var store: any PrimaryInventorySnapshotStore
        var validator: PrimaryInventorySnapshotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrimaryInventorySnapshotEngine

        init(store: any PrimaryInventorySnapshotStore, validator: PrimaryInventorySnapshotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrimaryInventorySnapshotEngine) {
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
                throw Kit.Failure("primary inventory snapshot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryInventorySnapshotStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary inventory snapshot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryInventorySnapshotStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary inventory snapshot \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newPrimaryInventorySnapshotWorkflow(_ store: any PrimaryInventorySnapshotStore, clock: any Kit.Clocks.Clock) -> PrimaryInventorySnapshotWorkflow {
        return PrimaryInventorySnapshotWorkflow(
            store: store,
            validator: defaultPrimaryInventorySnapshotValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrimaryInventorySnapshotEngine()
        )
    }
}
