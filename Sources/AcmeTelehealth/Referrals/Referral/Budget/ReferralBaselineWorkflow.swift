import AcmePlatform
import Foundation

extension Referrals {
    /// Moves referral baselines through their life cycle and keeps a journal of what it did.
    final class ReferralBaselineCoordinator {
        var store: any ReferralBaselineStore
        var validator: ReferralBaselineValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ReferralBaselineStore, validator: ReferralBaselineValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("referral baseline \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ReferralBaselineStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("referral baseline \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ReferralBaselineStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
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

    static func newReferralBaselineCoordinator(_ store: any ReferralBaselineStore, clock: any Kit.Clocks.Clock) -> ReferralBaselineCoordinator {
        return ReferralBaselineCoordinator(
            store: store,
            validator: defaultReferralBaselineValidator(),
            clock: clock,
            journal: []
        )
    }
}
