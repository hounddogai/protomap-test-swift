import AcmePlatform
import Foundation

extension Referrals {
    /// Moves referral preferences through their life cycle and keeps a journal of what it did.
    final class ReferralPreferenceWorkflow {
        var store: any ReferralPreferenceStore
        var validator: ReferralPreferenceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ReferralPreferenceStore, validator: ReferralPreferenceValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("referral preference \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ReferralPreferenceStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("referral preference \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ReferralPreferenceStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
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

    static func newReferralPreferenceWorkflow(_ store: any ReferralPreferenceStore, clock: any Kit.Clocks.Clock) -> ReferralPreferenceWorkflow {
        return ReferralPreferenceWorkflow(
            store: store,
            validator: defaultReferralPreferenceValidator(),
            clock: clock,
            journal: []
        )
    }
}
