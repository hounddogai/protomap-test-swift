import AcmePlatform
import Foundation

extension Referrals {
    /// Moves weighted referral cycles through their life cycle and keeps a journal of what it did.
    final class WeightedReferralCycleManager {
        var store: any WeightedReferralCycleStore
        var validator: WeightedReferralCycleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WeightedReferralCycleEngine

        init(store: any WeightedReferralCycleStore, validator: WeightedReferralCycleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WeightedReferralCycleEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted referral cycle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedReferralCycleStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted referral cycle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedReferralCycleStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted referral cycle \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newWeightedReferralCycleManager(_ store: any WeightedReferralCycleStore, clock: any Kit.Clocks.Clock) -> WeightedReferralCycleManager {
        return WeightedReferralCycleManager(
            store: store,
            validator: defaultWeightedReferralCycleValidator(),
            clock: clock,
            journal: [],
            engine: defaultWeightedReferralCycleEngine()
        )
    }
}
