import AcmePlatform
import Foundation

extension Referrals {
    /// Moves primary referral milestones through their life cycle and keeps a journal of what it did.
    final class PrimaryReferralMilestoneManager {
        var store: any PrimaryReferralMilestoneStore
        var validator: PrimaryReferralMilestoneValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrimaryReferralMilestoneEngine

        init(store: any PrimaryReferralMilestoneStore, validator: PrimaryReferralMilestoneValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrimaryReferralMilestoneEngine) {
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
                throw Kit.Failure("primary referral milestone \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryReferralMilestoneStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary referral milestone \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryReferralMilestoneStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary referral milestone \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newPrimaryReferralMilestoneManager(_ store: any PrimaryReferralMilestoneStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PrimaryReferralMilestoneManager {
        return PrimaryReferralMilestoneManager(
            store: store,
            validator: defaultPrimaryReferralMilestoneValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrimaryReferralMilestoneEngine(flags)
        )
    }
}
