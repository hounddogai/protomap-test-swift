import AcmePlatform
import Foundation

extension Referrals {
    /// Moves capped referral rollups through their life cycle and keeps a journal of what it did.
    final class CappedReferralRollupCoordinator {
        var store: any CappedReferralRollupStore
        var validator: CappedReferralRollupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CappedReferralRollupStore, validator: CappedReferralRollupValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped referral rollup \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedReferralRollupStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped referral rollup \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedReferralRollupStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
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

    static func newCappedReferralRollupCoordinator(_ store: any CappedReferralRollupStore, clock: any Kit.Clocks.Clock) -> CappedReferralRollupCoordinator {
        return CappedReferralRollupCoordinator(
            store: store,
            validator: defaultCappedReferralRollupValidator(),
            clock: clock,
            journal: []
        )
    }
}
