import AcmePlatform
import Foundation

extension Referrals {
    /// Moves pending follow up overrides through their life cycle and keeps a journal of what it did.
    final class PendingFollowUpOverrideService {
        var store: any PendingFollowUpOverrideStore
        var validator: PendingFollowUpOverrideValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PendingFollowUpOverrideStore, validator: PendingFollowUpOverrideValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("pending follow up override \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingFollowUpOverrideStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending follow up override \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingFollowUpOverrideStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newPendingFollowUpOverrideService(_ store: any PendingFollowUpOverrideStore, clock: any Kit.Clocks.Clock) -> PendingFollowUpOverrideService {
        return PendingFollowUpOverrideService(
            store: store,
            validator: defaultPendingFollowUpOverrideValidator(),
            clock: clock,
            journal: []
        )
    }
}
