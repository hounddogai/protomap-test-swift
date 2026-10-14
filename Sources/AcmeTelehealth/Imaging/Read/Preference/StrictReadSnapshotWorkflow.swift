import AcmePlatform
import Foundation

extension Imaging {
    /// Moves strict read snapshots through their life cycle and keeps a journal of what it did.
    final class StrictReadSnapshotDesk {
        var store: any StrictReadSnapshotStore
        var validator: StrictReadSnapshotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: StrictReadSnapshotEngine

        init(store: any StrictReadSnapshotStore, validator: StrictReadSnapshotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: StrictReadSnapshotEngine) {
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
                throw Kit.Failure("strict read snapshot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictReadSnapshotStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict read snapshot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictReadSnapshotStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict read snapshot \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newStrictReadSnapshotDesk(_ store: any StrictReadSnapshotStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> StrictReadSnapshotDesk {
        return StrictReadSnapshotDesk(
            store: store,
            validator: defaultStrictReadSnapshotValidator(),
            clock: clock,
            journal: [],
            engine: defaultStrictReadSnapshotEngine(flags)
        )
    }
}
