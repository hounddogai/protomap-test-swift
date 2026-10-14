import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves recall snapshots through their life cycle and keeps a journal of what it did.
    final class RecallSnapshotManager {
        var store: any RecallSnapshotStore
        var validator: RecallSnapshotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RecallSnapshotStore, validator: RecallSnapshotValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("recall snapshot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RecallSnapshotStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("recall snapshot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RecallSnapshotStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newRecallSnapshotManager(_ store: any RecallSnapshotStore, clock: any Kit.Clocks.Clock) -> RecallSnapshotManager {
        return RecallSnapshotManager(
            store: store,
            validator: defaultRecallSnapshotValidator(),
            clock: clock,
            journal: []
        )
    }
}
