import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves regional alert snapshots through their life cycle and keeps a journal of what it did.
    final class RegionalAlertSnapshotWorkflow {
        var store: any RegionalAlertSnapshotStore
        var validator: RegionalAlertSnapshotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RegionalAlertSnapshotEngine

        init(store: any RegionalAlertSnapshotStore, validator: RegionalAlertSnapshotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RegionalAlertSnapshotEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional alert snapshot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalAlertSnapshotStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional alert snapshot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalAlertSnapshotStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional alert snapshot \(code) not found")
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

    static func newRegionalAlertSnapshotWorkflow(_ store: any RegionalAlertSnapshotStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RegionalAlertSnapshotWorkflow {
        return RegionalAlertSnapshotWorkflow(
            store: store,
            validator: defaultRegionalAlertSnapshotValidator(),
            clock: clock,
            journal: [],
            engine: defaultRegionalAlertSnapshotEngine(flags)
        )
    }
}
