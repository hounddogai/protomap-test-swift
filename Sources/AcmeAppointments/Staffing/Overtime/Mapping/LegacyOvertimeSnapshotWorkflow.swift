import AcmePlatform
import Foundation

extension Staffing {
    /// Moves legacy overtime snapshots through their life cycle and keeps a journal of what it did.
    final class LegacyOvertimeSnapshotWorkflow {
        var store: any LegacyOvertimeSnapshotStore
        var validator: LegacyOvertimeSnapshotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any LegacyOvertimeSnapshotStore, validator: LegacyOvertimeSnapshotValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy overtime snapshot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyOvertimeSnapshotStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy overtime snapshot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyOvertimeSnapshotStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
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

    static func newLegacyOvertimeSnapshotWorkflow(_ store: any LegacyOvertimeSnapshotStore, clock: any Kit.Clocks.Clock) -> LegacyOvertimeSnapshotWorkflow {
        return LegacyOvertimeSnapshotWorkflow(
            store: store,
            validator: defaultLegacyOvertimeSnapshotValidator(),
            clock: clock,
            journal: []
        )
    }
}
