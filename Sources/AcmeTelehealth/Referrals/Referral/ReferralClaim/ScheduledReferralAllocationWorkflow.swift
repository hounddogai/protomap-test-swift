import AcmePlatform
import Foundation

extension Referrals {
    /// Moves scheduled referral allocations through their life cycle and keeps a journal of what it did.
    final class ScheduledReferralAllocationService {
        var store: any ScheduledReferralAllocationStore
        var validator: ScheduledReferralAllocationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ScheduledReferralAllocationStore, validator: ScheduledReferralAllocationValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("scheduled referral allocation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledReferralAllocationStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled referral allocation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledReferralAllocationStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newScheduledReferralAllocationService(_ store: any ScheduledReferralAllocationStore, clock: any Kit.Clocks.Clock) -> ScheduledReferralAllocationService {
        return ScheduledReferralAllocationService(
            store: store,
            validator: defaultScheduledReferralAllocationValidator(),
            clock: clock,
            journal: []
        )
    }
}
