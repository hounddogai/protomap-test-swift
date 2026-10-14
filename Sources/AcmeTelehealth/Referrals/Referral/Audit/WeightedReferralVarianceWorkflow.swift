import AcmePlatform
import Foundation

extension Referrals {
    /// Moves weighted referral variances through their life cycle and keeps a journal of what it did.
    final class WeightedReferralVarianceManager {
        var store: any WeightedReferralVarianceStore
        var validator: WeightedReferralVarianceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any WeightedReferralVarianceStore, validator: WeightedReferralVarianceValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("weighted referral variance \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedReferralVarianceStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted referral variance \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedReferralVarianceStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
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

    static func newWeightedReferralVarianceManager(_ store: any WeightedReferralVarianceStore, clock: any Kit.Clocks.Clock) -> WeightedReferralVarianceManager {
        return WeightedReferralVarianceManager(
            store: store,
            validator: defaultWeightedReferralVarianceValidator(),
            clock: clock,
            journal: []
        )
    }
}
