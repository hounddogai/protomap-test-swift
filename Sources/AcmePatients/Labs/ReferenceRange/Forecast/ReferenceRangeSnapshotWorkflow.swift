import AcmePlatform
import Foundation

extension Labs {
    /// Moves reference range snapshots through their life cycle and keeps a journal of what it did.
    final class ReferenceRangeSnapshotManager {
        var store: any ReferenceRangeSnapshotStore
        var validator: ReferenceRangeSnapshotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ReferenceRangeSnapshotEngine

        init(store: any ReferenceRangeSnapshotStore, validator: ReferenceRangeSnapshotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ReferenceRangeSnapshotEngine) {
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
                throw Kit.Failure("reference range snapshot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ReferenceRangeSnapshotStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("reference range snapshot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ReferenceRangeSnapshotStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("reference range snapshot \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newReferenceRangeSnapshotManager(_ store: any ReferenceRangeSnapshotStore, clock: any Kit.Clocks.Clock) -> ReferenceRangeSnapshotManager {
        return ReferenceRangeSnapshotManager(
            store: store,
            validator: defaultReferenceRangeSnapshotValidator(),
            clock: clock,
            journal: [],
            engine: defaultReferenceRangeSnapshotEngine()
        )
    }
}
