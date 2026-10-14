import AcmePlatform
import Foundation

extension Referrals {
    /// Moves referral drafts through their life cycle and keeps a journal of what it did.
    final class ReferralDraftDesk {
        var store: any ReferralDraftStore
        var validator: ReferralDraftValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ReferralDraftStore, validator: ReferralDraftValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("referral draft \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ReferralDraftStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("referral draft \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ReferralDraftStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newReferralDraftDesk(_ store: any ReferralDraftStore, clock: any Kit.Clocks.Clock) -> ReferralDraftDesk {
        return ReferralDraftDesk(store: store, validator: defaultReferralDraftValidator(), clock: clock, journal: [])
    }
}
