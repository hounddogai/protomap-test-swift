import AcmePlatform
import Foundation

extension Referrals {
    /// Moves follow up groups through their life cycle and keeps a journal of what it did.
    final class FollowUpGroupService {
        var store: any FollowUpGroupStore
        var validator: FollowUpGroupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any FollowUpGroupStore, validator: FollowUpGroupValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("follow up group \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FollowUpGroupStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("follow up group \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FollowUpGroupStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newFollowUpGroupService(_ store: any FollowUpGroupStore, clock: any Kit.Clocks.Clock) -> FollowUpGroupService {
        return FollowUpGroupService(
            store: store,
            validator: defaultFollowUpGroupValidator(),
            clock: clock,
            journal: []
        )
    }
}
