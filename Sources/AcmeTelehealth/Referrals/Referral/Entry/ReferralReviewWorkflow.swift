import AcmePlatform
import Foundation

extension Referrals {
    /// Moves referral reviews through their life cycle and keeps a journal of what it did.
    final class ReferralReviewCoordinator {
        var store: any ReferralReviewStore
        var validator: ReferralReviewValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ReferralReviewEngine

        init(store: any ReferralReviewStore, validator: ReferralReviewValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ReferralReviewEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("referral review \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ReferralReviewStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("referral review \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ReferralReviewStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("referral review \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newReferralReviewCoordinator(_ store: any ReferralReviewStore, clock: any Kit.Clocks.Clock) -> ReferralReviewCoordinator {
        return ReferralReviewCoordinator(
            store: store,
            validator: defaultReferralReviewValidator(),
            clock: clock,
            journal: [],
            engine: defaultReferralReviewEngine()
        )
    }
}
