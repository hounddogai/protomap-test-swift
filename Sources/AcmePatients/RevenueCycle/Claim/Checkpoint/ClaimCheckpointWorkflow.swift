import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves claim checkpoints through their life cycle and keeps a journal of what it did.
    final class ClaimCheckpointDesk {
        var store: any ClaimCheckpointStore
        var validator: ClaimCheckpointValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ClaimCheckpointStore, validator: ClaimCheckpointValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("claim checkpoint \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ClaimCheckpointStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("claim checkpoint \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ClaimCheckpointStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newClaimCheckpointDesk(_ store: any ClaimCheckpointStore, clock: any Kit.Clocks.Clock) -> ClaimCheckpointDesk {
        return ClaimCheckpointDesk(
            store: store,
            validator: defaultClaimCheckpointValidator(),
            clock: clock,
            journal: []
        )
    }
}
