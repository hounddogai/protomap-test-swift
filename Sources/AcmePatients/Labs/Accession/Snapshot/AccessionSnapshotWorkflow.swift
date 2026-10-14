import AcmePlatform
import Foundation

extension Labs {
    /// Moves accession snapshots through their life cycle and keeps a journal of what it did.
    final class AccessionSnapshotWorkflow {
        var store: any AccessionSnapshotStore
        var validator: AccessionSnapshotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AccessionSnapshotEngine

        init(store: any AccessionSnapshotStore, validator: AccessionSnapshotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AccessionSnapshotEngine) {
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
                throw Kit.Failure("accession snapshot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AccessionSnapshotStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("accession snapshot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AccessionSnapshotStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("accession snapshot \(code) not found")
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

    static func newAccessionSnapshotWorkflow(_ store: any AccessionSnapshotStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> AccessionSnapshotWorkflow {
        return AccessionSnapshotWorkflow(
            store: store,
            validator: defaultAccessionSnapshotValidator(),
            clock: clock,
            journal: [],
            engine: defaultAccessionSnapshotEngine(flags)
        )
    }
}
