import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves capped statement snapshots through their life cycle and keeps a journal of what it did.
    final class CappedStatementSnapshotDesk {
        var store: any CappedStatementSnapshotStore
        var validator: CappedStatementSnapshotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CappedStatementSnapshotStore, validator: CappedStatementSnapshotValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("capped statement snapshot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedStatementSnapshotStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped statement snapshot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedStatementSnapshotStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
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

    static func newCappedStatementSnapshotDesk(_ store: any CappedStatementSnapshotStore, clock: any Kit.Clocks.Clock) -> CappedStatementSnapshotDesk {
        return CappedStatementSnapshotDesk(
            store: store,
            validator: defaultCappedStatementSnapshotValidator(),
            clock: clock,
            journal: []
        )
    }
}
