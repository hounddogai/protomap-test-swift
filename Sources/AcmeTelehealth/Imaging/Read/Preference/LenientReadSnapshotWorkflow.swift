import AcmePlatform
import Foundation

extension Imaging {
    /// Moves lenient read snapshots through their life cycle and keeps a journal of what it did.
    final class LenientReadSnapshotWorkflow {
        var store: any LenientReadSnapshotStore
        var validator: LenientReadSnapshotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LenientReadSnapshotEngine

        init(store: any LenientReadSnapshotStore, validator: LenientReadSnapshotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LenientReadSnapshotEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient read snapshot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientReadSnapshotStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient read snapshot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientReadSnapshotStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient read snapshot \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newLenientReadSnapshotWorkflow(_ store: any LenientReadSnapshotStore, clock: any Kit.Clocks.Clock) -> LenientReadSnapshotWorkflow {
        return LenientReadSnapshotWorkflow(
            store: store,
            validator: defaultLenientReadSnapshotValidator(),
            clock: clock,
            journal: [],
            engine: defaultLenientReadSnapshotEngine()
        )
    }
}
