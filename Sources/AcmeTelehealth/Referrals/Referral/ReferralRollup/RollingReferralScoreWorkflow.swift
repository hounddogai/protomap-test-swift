import AcmePlatform
import Foundation

extension Referrals {
    /// Moves rolling referral scores through their life cycle and keeps a journal of what it did.
    final class RollingReferralScoreCoordinator {
        var store: any RollingReferralScoreStore
        var validator: RollingReferralScoreValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RollingReferralScoreEngine

        init(store: any RollingReferralScoreStore, validator: RollingReferralScoreValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RollingReferralScoreEngine) {
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
                throw Kit.Failure("rolling referral score \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingReferralScoreStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling referral score \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingReferralScoreStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling referral score \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newRollingReferralScoreCoordinator(_ store: any RollingReferralScoreStore, clock: any Kit.Clocks.Clock) -> RollingReferralScoreCoordinator {
        return RollingReferralScoreCoordinator(
            store: store,
            validator: defaultRollingReferralScoreValidator(),
            clock: clock,
            journal: [],
            engine: defaultRollingReferralScoreEngine()
        )
    }
}
