import AcmePlatform
import Foundation

extension Referrals {
    /// Moves tiered eligibility snapshots through their life cycle and keeps a journal of what it did.
    final class TieredEligibilitySnapshotService {
        var store: any TieredEligibilitySnapshotStore
        var validator: TieredEligibilitySnapshotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TieredEligibilitySnapshotEngine

        init(store: any TieredEligibilitySnapshotStore, validator: TieredEligibilitySnapshotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TieredEligibilitySnapshotEngine) {
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
                throw Kit.Failure("tiered eligibility snapshot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredEligibilitySnapshotStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered eligibility snapshot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredEligibilitySnapshotStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered eligibility snapshot \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newTieredEligibilitySnapshotService(_ store: any TieredEligibilitySnapshotStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> TieredEligibilitySnapshotService {
        return TieredEligibilitySnapshotService(
            store: store,
            validator: defaultTieredEligibilitySnapshotValidator(),
            clock: clock,
            journal: [],
            engine: defaultTieredEligibilitySnapshotEngine(flags)
        )
    }
}
