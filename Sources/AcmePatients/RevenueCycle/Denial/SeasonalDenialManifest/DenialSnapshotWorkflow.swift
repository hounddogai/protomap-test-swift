import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves denial snapshots through their life cycle and keeps a journal of what it did.
    final class DenialSnapshotManager {
        var store: any DenialSnapshotStore
        var validator: DenialSnapshotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DenialSnapshotEngine

        init(store: any DenialSnapshotStore, validator: DenialSnapshotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DenialSnapshotEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("denial snapshot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DenialSnapshotStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("denial snapshot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DenialSnapshotStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("denial snapshot \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newDenialSnapshotManager(_ store: any DenialSnapshotStore, clock: any Kit.Clocks.Clock) -> DenialSnapshotManager {
        return DenialSnapshotManager(
            store: store,
            validator: defaultDenialSnapshotValidator(),
            clock: clock,
            journal: [],
            engine: defaultDenialSnapshotEngine()
        )
    }
}
