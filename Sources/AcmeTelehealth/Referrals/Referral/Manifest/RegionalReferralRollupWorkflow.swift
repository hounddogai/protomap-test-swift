import AcmePlatform
import Foundation

extension Referrals {
    /// Moves regional referral rollups through their life cycle and keeps a journal of what it did.
    final class RegionalReferralRollupService {
        var store: any RegionalReferralRollupStore
        var validator: RegionalReferralRollupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RegionalReferralRollupStore, validator: RegionalReferralRollupValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional referral rollup \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalReferralRollupStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional referral rollup \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalReferralRollupStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newRegionalReferralRollupService(_ store: any RegionalReferralRollupStore, clock: any Kit.Clocks.Clock) -> RegionalReferralRollupService {
        return RegionalReferralRollupService(
            store: store,
            validator: defaultRegionalReferralRollupValidator(),
            clock: clock,
            journal: []
        )
    }
}
