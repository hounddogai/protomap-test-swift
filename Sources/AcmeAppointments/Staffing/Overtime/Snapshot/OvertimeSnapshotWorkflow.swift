import AcmePlatform
import Foundation

extension Staffing {
    /// Moves overtime snapshots through their life cycle and keeps a journal of what it did.
    final class OvertimeSnapshotWorkflow {
        var store: any OvertimeSnapshotStore
        var validator: OvertimeSnapshotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any OvertimeSnapshotStore, validator: OvertimeSnapshotValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("overtime snapshot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(OvertimeSnapshotStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("overtime snapshot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(OvertimeSnapshotStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newOvertimeSnapshotWorkflow(_ store: any OvertimeSnapshotStore, clock: any Kit.Clocks.Clock) -> OvertimeSnapshotWorkflow {
        return OvertimeSnapshotWorkflow(
            store: store,
            validator: defaultOvertimeSnapshotValidator(),
            clock: clock,
            journal: []
        )
    }
}
