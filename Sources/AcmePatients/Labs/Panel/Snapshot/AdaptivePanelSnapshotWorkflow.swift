import AcmePlatform
import Foundation

extension Labs {
    /// Moves adaptive panel snapshots through their life cycle and keeps a journal of what it did.
    final class AdaptivePanelSnapshotManager {
        var store: any AdaptivePanelSnapshotStore
        var validator: AdaptivePanelSnapshotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any AdaptivePanelSnapshotStore, validator: AdaptivePanelSnapshotValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("adaptive panel snapshot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptivePanelSnapshotStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive panel snapshot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptivePanelSnapshotStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newAdaptivePanelSnapshotManager(_ store: any AdaptivePanelSnapshotStore, clock: any Kit.Clocks.Clock) -> AdaptivePanelSnapshotManager {
        return AdaptivePanelSnapshotManager(
            store: store,
            validator: defaultAdaptivePanelSnapshotValidator(),
            clock: clock,
            journal: []
        )
    }
}
