import AcmePlatform
import Foundation

extension Imaging {
    /// Moves regional study snapshots through their life cycle and keeps a journal of what it did.
    final class RegionalStudySnapshotDesk {
        var store: any RegionalStudySnapshotStore
        var validator: RegionalStudySnapshotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RegionalStudySnapshotEngine

        init(store: any RegionalStudySnapshotStore, validator: RegionalStudySnapshotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RegionalStudySnapshotEngine) {
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
                throw Kit.Failure("regional study snapshot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalStudySnapshotStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional study snapshot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalStudySnapshotStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional study snapshot \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newRegionalStudySnapshotDesk(_ store: any RegionalStudySnapshotStore, clock: any Kit.Clocks.Clock) -> RegionalStudySnapshotDesk {
        return RegionalStudySnapshotDesk(
            store: store,
            validator: defaultRegionalStudySnapshotValidator(),
            clock: clock,
            journal: [],
            engine: defaultRegionalStudySnapshotEngine()
        )
    }
}
