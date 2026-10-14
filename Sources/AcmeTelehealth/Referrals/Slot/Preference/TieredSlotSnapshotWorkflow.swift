import AcmePlatform
import Foundation

extension Referrals {
    /// Moves tiered slot snapshots through their life cycle and keeps a journal of what it did.
    final class TieredSlotSnapshotService {
        var store: any TieredSlotSnapshotStore
        var validator: TieredSlotSnapshotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any TieredSlotSnapshotStore, validator: TieredSlotSnapshotValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("tiered slot snapshot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredSlotSnapshotStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered slot snapshot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredSlotSnapshotStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newTieredSlotSnapshotService(_ store: any TieredSlotSnapshotStore, clock: any Kit.Clocks.Clock) -> TieredSlotSnapshotService {
        return TieredSlotSnapshotService(
            store: store,
            validator: defaultTieredSlotSnapshotValidator(),
            clock: clock,
            journal: []
        )
    }
}
