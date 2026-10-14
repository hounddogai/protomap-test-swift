import AcmePlatform
import Foundation

extension Referrals {
    /// Moves referral targets through their life cycle and keeps a journal of what it did.
    final class ReferralTargetCoordinator {
        var store: any ReferralTargetStore
        var validator: ReferralTargetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ReferralTargetEngine

        init(store: any ReferralTargetStore, validator: ReferralTargetValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ReferralTargetEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("referral target \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ReferralTargetStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("referral target \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ReferralTargetStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("referral target \(code) not found")
            }
            let result = engine.price(item)
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

    static func newReferralTargetCoordinator(_ store: any ReferralTargetStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ReferralTargetCoordinator {
        return ReferralTargetCoordinator(
            store: store,
            validator: defaultReferralTargetValidator(),
            clock: clock,
            journal: [],
            engine: defaultReferralTargetEngine(flags)
        )
    }
}
