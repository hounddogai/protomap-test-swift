import AcmePlatform
import Foundation

extension Referrals {
    /// Moves pending referral claims through their life cycle and keeps a journal of what it did.
    final class PendingReferralClaimCoordinator {
        var store: any PendingReferralClaimStore
        var validator: PendingReferralClaimValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PendingReferralClaimStore, validator: PendingReferralClaimValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("pending referral claim \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingReferralClaimStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending referral claim \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingReferralClaimStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
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

    static func newPendingReferralClaimCoordinator(_ store: any PendingReferralClaimStore, clock: any Kit.Clocks.Clock) -> PendingReferralClaimCoordinator {
        return PendingReferralClaimCoordinator(
            store: store,
            validator: defaultPendingReferralClaimValidator(),
            clock: clock,
            journal: []
        )
    }
}
