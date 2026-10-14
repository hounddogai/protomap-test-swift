import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves rolling inventory snapshots through their life cycle and keeps a journal of what it did.
    final class RollingInventorySnapshotService {
        var store: any RollingInventorySnapshotStore
        var validator: RollingInventorySnapshotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RollingInventorySnapshotEngine

        init(store: any RollingInventorySnapshotStore, validator: RollingInventorySnapshotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RollingInventorySnapshotEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling inventory snapshot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingInventorySnapshotStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling inventory snapshot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingInventorySnapshotStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling inventory snapshot \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
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

    static func newRollingInventorySnapshotService(_ store: any RollingInventorySnapshotStore, clock: any Kit.Clocks.Clock) -> RollingInventorySnapshotService {
        return RollingInventorySnapshotService(
            store: store,
            validator: defaultRollingInventorySnapshotValidator(),
            clock: clock,
            journal: [],
            engine: defaultRollingInventorySnapshotEngine()
        )
    }
}
