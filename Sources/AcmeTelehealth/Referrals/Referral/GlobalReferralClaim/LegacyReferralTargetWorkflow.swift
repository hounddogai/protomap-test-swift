import AcmePlatform
import Foundation

extension Referrals {
    /// Moves legacy referral targets through their life cycle and keeps a journal of what it did.
    final class LegacyReferralTargetService {
        var store: any LegacyReferralTargetStore
        var validator: LegacyReferralTargetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LegacyReferralTargetEngine

        init(store: any LegacyReferralTargetStore, validator: LegacyReferralTargetValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LegacyReferralTargetEngine) {
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
                throw Kit.Failure("legacy referral target \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyReferralTargetStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy referral target \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyReferralTargetStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy referral target \(code) not found")
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

    static func newLegacyReferralTargetService(_ store: any LegacyReferralTargetStore, clock: any Kit.Clocks.Clock) -> LegacyReferralTargetService {
        return LegacyReferralTargetService(
            store: store,
            validator: defaultLegacyReferralTargetValidator(),
            clock: clock,
            journal: [],
            engine: defaultLegacyReferralTargetEngine()
        )
    }
}
