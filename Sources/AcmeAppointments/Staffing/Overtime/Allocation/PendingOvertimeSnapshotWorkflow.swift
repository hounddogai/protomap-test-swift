import AcmePlatform
import Foundation

extension Staffing {
    /// Moves pending overtime snapshots through their life cycle and keeps a journal of what it did.
    final class PendingOvertimeSnapshotManager {
        var store: any PendingOvertimeSnapshotStore
        var validator: PendingOvertimeSnapshotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PendingOvertimeSnapshotStore, validator: PendingOvertimeSnapshotValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending overtime snapshot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingOvertimeSnapshotStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending overtime snapshot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingOvertimeSnapshotStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
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

    static func newPendingOvertimeSnapshotManager(_ store: any PendingOvertimeSnapshotStore, clock: any Kit.Clocks.Clock) -> PendingOvertimeSnapshotManager {
        return PendingOvertimeSnapshotManager(
            store: store,
            validator: defaultPendingOvertimeSnapshotValidator(),
            clock: clock,
            journal: []
        )
    }
}
