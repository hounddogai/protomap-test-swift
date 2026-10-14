import AcmePlatform
import Foundation

extension Referrals {
    /// Moves referral digests through their life cycle and keeps a journal of what it did.
    final class ReferralDigestManager {
        var store: any ReferralDigestStore
        var validator: ReferralDigestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ReferralDigestEngine

        init(store: any ReferralDigestStore, validator: ReferralDigestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ReferralDigestEngine) {
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
                throw Kit.Failure("referral digest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ReferralDigestStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("referral digest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ReferralDigestStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("referral digest \(code) not found")
            }
            let result = engine.run(item)
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

    static func newReferralDigestManager(_ store: any ReferralDigestStore, clock: any Kit.Clocks.Clock) -> ReferralDigestManager {
        return ReferralDigestManager(
            store: store,
            validator: defaultReferralDigestValidator(),
            clock: clock,
            journal: [],
            engine: defaultReferralDigestEngine()
        )
    }
}
