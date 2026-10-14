import AcmePlatform
import Foundation

extension Referrals {
    /// Moves rolling referral exceptions through their life cycle and keeps a journal of what it did.
    final class RollingReferralExceptionCoordinator {
        var store: any RollingReferralExceptionStore
        var validator: RollingReferralExceptionValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RollingReferralExceptionEngine

        init(store: any RollingReferralExceptionStore, validator: RollingReferralExceptionValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RollingReferralExceptionEngine) {
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
                throw Kit.Failure("rolling referral exception \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingReferralExceptionStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling referral exception \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingReferralExceptionStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling referral exception \(code) not found")
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

    static func newRollingReferralExceptionCoordinator(_ store: any RollingReferralExceptionStore, clock: any Kit.Clocks.Clock) -> RollingReferralExceptionCoordinator {
        return RollingReferralExceptionCoordinator(
            store: store,
            validator: defaultRollingReferralExceptionValidator(),
            clock: clock,
            journal: [],
            engine: defaultRollingReferralExceptionEngine()
        )
    }
}
