import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves default formulary snapshots through their life cycle and keeps a journal of what it did.
    final class DefaultFormularySnapshotWorkflow {
        var store: any DefaultFormularySnapshotStore
        var validator: DefaultFormularySnapshotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any DefaultFormularySnapshotStore, validator: DefaultFormularySnapshotValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default formulary snapshot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultFormularySnapshotStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default formulary snapshot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultFormularySnapshotStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newDefaultFormularySnapshotWorkflow(_ store: any DefaultFormularySnapshotStore, clock: any Kit.Clocks.Clock) -> DefaultFormularySnapshotWorkflow {
        return DefaultFormularySnapshotWorkflow(
            store: store,
            validator: defaultDefaultFormularySnapshotValidator(),
            clock: clock,
            journal: []
        )
    }
}
