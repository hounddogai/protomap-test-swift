import AcmePlatform
import Foundation

extension Referrals {
    /// Moves follow up schedules through their life cycle and keeps a journal of what it did.
    final class FollowUpScheduleManager {
        var store: any FollowUpScheduleStore
        var validator: FollowUpScheduleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any FollowUpScheduleStore, validator: FollowUpScheduleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("follow up schedule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FollowUpScheduleStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("follow up schedule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FollowUpScheduleStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newFollowUpScheduleManager(_ store: any FollowUpScheduleStore, clock: any Kit.Clocks.Clock) -> FollowUpScheduleManager {
        return FollowUpScheduleManager(
            store: store,
            validator: defaultFollowUpScheduleValidator(),
            clock: clock,
            journal: []
        )
    }
}
