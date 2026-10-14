import AcmePlatform
import Foundation

extension Consent {
    /// Moves consent form snapshots through their life cycle and keeps a journal of what it did.
    final class ConsentFormSnapshotWorkflow {
        var store: any ConsentFormSnapshotStore
        var validator: ConsentFormSnapshotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ConsentFormSnapshotStore, validator: ConsentFormSnapshotValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("consent form snapshot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ConsentFormSnapshotStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("consent form snapshot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ConsentFormSnapshotStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newConsentFormSnapshotWorkflow(_ store: any ConsentFormSnapshotStore, clock: any Kit.Clocks.Clock) -> ConsentFormSnapshotWorkflow {
        return ConsentFormSnapshotWorkflow(
            store: store,
            validator: defaultConsentFormSnapshotValidator(),
            clock: clock,
            journal: []
        )
    }
}
