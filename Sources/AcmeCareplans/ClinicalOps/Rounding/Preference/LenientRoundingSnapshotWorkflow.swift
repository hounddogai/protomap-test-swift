import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves lenient rounding snapshots through their life cycle and keeps a journal of what it did.
    final class LenientRoundingSnapshotManager {
        var store: any LenientRoundingSnapshotStore
        var validator: LenientRoundingSnapshotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LenientRoundingSnapshotEngine

        init(store: any LenientRoundingSnapshotStore, validator: LenientRoundingSnapshotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LenientRoundingSnapshotEngine) {
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
                throw Kit.Failure("lenient rounding snapshot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientRoundingSnapshotStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient rounding snapshot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientRoundingSnapshotStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient rounding snapshot \(code) not found")
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

    static func newLenientRoundingSnapshotManager(_ store: any LenientRoundingSnapshotStore, clock: any Kit.Clocks.Clock) -> LenientRoundingSnapshotManager {
        return LenientRoundingSnapshotManager(
            store: store,
            validator: defaultLenientRoundingSnapshotValidator(),
            clock: clock,
            journal: [],
            engine: defaultLenientRoundingSnapshotEngine()
        )
    }
}
