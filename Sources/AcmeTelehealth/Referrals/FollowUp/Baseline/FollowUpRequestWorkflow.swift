import AcmePlatform
import Foundation

extension Referrals {
    /// Moves follow up requests through their life cycle and keeps a journal of what it did.
    final class FollowUpRequestService {
        var store: any FollowUpRequestStore
        var validator: FollowUpRequestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any FollowUpRequestStore, validator: FollowUpRequestValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("follow up request \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FollowUpRequestStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("follow up request \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FollowUpRequestStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
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

    static func newFollowUpRequestService(_ store: any FollowUpRequestStore, clock: any Kit.Clocks.Clock) -> FollowUpRequestService {
        return FollowUpRequestService(
            store: store,
            validator: defaultFollowUpRequestValidator(),
            clock: clock,
            journal: []
        )
    }
}
