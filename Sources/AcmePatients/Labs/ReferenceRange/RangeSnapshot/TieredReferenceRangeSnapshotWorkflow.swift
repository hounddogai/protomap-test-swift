import AcmePlatform
import Foundation

extension Labs {
    /// Moves tiered reference range snapshots through their life cycle and keeps a journal of what it did.
    final class TieredReferenceRangeSnapshotManager {
        var store: any TieredReferenceRangeSnapshotStore
        var validator: TieredReferenceRangeSnapshotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any TieredReferenceRangeSnapshotStore, validator: TieredReferenceRangeSnapshotValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("tiered reference range snapshot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredReferenceRangeSnapshotStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered reference range snapshot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredReferenceRangeSnapshotStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newTieredReferenceRangeSnapshotManager(_ store: any TieredReferenceRangeSnapshotStore, clock: any Kit.Clocks.Clock) -> TieredReferenceRangeSnapshotManager {
        return TieredReferenceRangeSnapshotManager(
            store: store,
            validator: defaultTieredReferenceRangeSnapshotValidator(),
            clock: clock,
            journal: []
        )
    }
}
