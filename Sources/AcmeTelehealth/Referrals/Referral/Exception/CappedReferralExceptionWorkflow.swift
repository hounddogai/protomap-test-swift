import AcmePlatform
import Foundation

extension Referrals {
    /// Moves capped referral exceptions through their life cycle and keeps a journal of what it did.
    final class CappedReferralExceptionService {
        var store: any CappedReferralExceptionStore
        var validator: CappedReferralExceptionValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CappedReferralExceptionEngine

        init(store: any CappedReferralExceptionStore, validator: CappedReferralExceptionValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CappedReferralExceptionEngine) {
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
                throw Kit.Failure("capped referral exception \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedReferralExceptionStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped referral exception \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedReferralExceptionStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped referral exception \(code) not found")
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

    static func newCappedReferralExceptionService(_ store: any CappedReferralExceptionStore, clock: any Kit.Clocks.Clock) -> CappedReferralExceptionService {
        return CappedReferralExceptionService(
            store: store,
            validator: defaultCappedReferralExceptionValidator(),
            clock: clock,
            journal: [],
            engine: defaultCappedReferralExceptionEngine()
        )
    }
}
