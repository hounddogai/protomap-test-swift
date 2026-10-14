import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves lenient order set snapshots through their life cycle and keeps a journal of what it did.
    final class LenientOrderSetSnapshotWorkflow {
        var store: any LenientOrderSetSnapshotStore
        var validator: LenientOrderSetSnapshotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LenientOrderSetSnapshotEngine

        init(store: any LenientOrderSetSnapshotStore, validator: LenientOrderSetSnapshotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LenientOrderSetSnapshotEngine) {
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
                throw Kit.Failure("lenient order set snapshot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientOrderSetSnapshotStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient order set snapshot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientOrderSetSnapshotStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient order set snapshot \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newLenientOrderSetSnapshotWorkflow(_ store: any LenientOrderSetSnapshotStore, clock: any Kit.Clocks.Clock) -> LenientOrderSetSnapshotWorkflow {
        return LenientOrderSetSnapshotWorkflow(
            store: store,
            validator: defaultLenientOrderSetSnapshotValidator(),
            clock: clock,
            journal: [],
            engine: defaultLenientOrderSetSnapshotEngine()
        )
    }
}
