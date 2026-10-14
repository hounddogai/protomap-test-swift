import AcmePlatform
import Foundation

extension Referrals {
    /// Moves referral budgets through their life cycle and keeps a journal of what it did.
    final class ReferralBudgetWorkflow {
        var store: any ReferralBudgetStore
        var validator: ReferralBudgetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ReferralBudgetEngine

        init(store: any ReferralBudgetStore, validator: ReferralBudgetValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ReferralBudgetEngine) {
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
                throw Kit.Failure("referral budget \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ReferralBudgetStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("referral budget \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ReferralBudgetStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("referral budget \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newReferralBudgetWorkflow(_ store: any ReferralBudgetStore, clock: any Kit.Clocks.Clock) -> ReferralBudgetWorkflow {
        return ReferralBudgetWorkflow(
            store: store,
            validator: defaultReferralBudgetValidator(),
            clock: clock,
            journal: [],
            engine: defaultReferralBudgetEngine()
        )
    }
}
