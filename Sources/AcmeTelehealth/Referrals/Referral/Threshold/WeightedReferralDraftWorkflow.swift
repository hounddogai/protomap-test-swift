import AcmePlatform
import Foundation

extension Referrals {
    /// Moves weighted referral drafts through their life cycle and keeps a journal of what it did.
    final class WeightedReferralDraftDesk {
        var store: any WeightedReferralDraftStore
        var validator: WeightedReferralDraftValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WeightedReferralDraftEngine

        init(store: any WeightedReferralDraftStore, validator: WeightedReferralDraftValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WeightedReferralDraftEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted referral draft \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedReferralDraftStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted referral draft \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedReferralDraftStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted referral draft \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
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

    static func newWeightedReferralDraftDesk(_ store: any WeightedReferralDraftStore, clock: any Kit.Clocks.Clock) -> WeightedReferralDraftDesk {
        return WeightedReferralDraftDesk(
            store: store,
            validator: defaultWeightedReferralDraftValidator(),
            clock: clock,
            journal: [],
            engine: defaultWeightedReferralDraftEngine()
        )
    }
}
