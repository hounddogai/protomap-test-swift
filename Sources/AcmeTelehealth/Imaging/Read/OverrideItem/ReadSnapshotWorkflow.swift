import AcmePlatform
import Foundation

extension Imaging {
    /// Moves read snapshots through their life cycle and keeps a journal of what it did.
    final class ReadSnapshotWorkflow {
        var store: any ReadSnapshotStore
        var validator: ReadSnapshotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ReadSnapshotEngine

        init(store: any ReadSnapshotStore, validator: ReadSnapshotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ReadSnapshotEngine) {
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
                throw Kit.Failure("read snapshot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ReadSnapshotStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("read snapshot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ReadSnapshotStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("read snapshot \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newReadSnapshotWorkflow(_ store: any ReadSnapshotStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ReadSnapshotWorkflow {
        return ReadSnapshotWorkflow(
            store: store,
            validator: defaultReadSnapshotValidator(),
            clock: clock,
            journal: [],
            engine: defaultReadSnapshotEngine(flags)
        )
    }
}
