import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves rolling inventory drafts through their life cycle and keeps a journal of what it did.
    final class RollingInventoryDraftDesk {
        var store: any RollingInventoryDraftStore
        var validator: RollingInventoryDraftValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RollingInventoryDraftStore, validator: RollingInventoryDraftValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("rolling inventory draft \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingInventoryDraftStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling inventory draft \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingInventoryDraftStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
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

    static func newRollingInventoryDraftDesk(_ store: any RollingInventoryDraftStore, clock: any Kit.Clocks.Clock) -> RollingInventoryDraftDesk {
        return RollingInventoryDraftDesk(
            store: store,
            validator: defaultRollingInventoryDraftValidator(),
            clock: clock,
            journal: []
        )
    }
}
