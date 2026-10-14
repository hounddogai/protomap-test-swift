import AcmePlatform
import Foundation

extension Referrals {
    /// Moves follow up profiles through their life cycle and keeps a journal of what it did.
    final class FollowUpProfileDesk {
        var store: any FollowUpProfileStore
        var validator: FollowUpProfileValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any FollowUpProfileStore, validator: FollowUpProfileValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("follow up profile \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FollowUpProfileStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("follow up profile \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FollowUpProfileStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newFollowUpProfileDesk(_ store: any FollowUpProfileStore, clock: any Kit.Clocks.Clock) -> FollowUpProfileDesk {
        return FollowUpProfileDesk(
            store: store,
            validator: defaultFollowUpProfileValidator(),
            clock: clock,
            journal: []
        )
    }
}
