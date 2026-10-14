import AcmePlatform
import Foundation

extension Referrals {
    /// Moves referral thresholds through their life cycle and keeps a journal of what it did.
    final class ReferralThresholdDesk {
        var store: any ReferralThresholdStore
        var validator: ReferralThresholdValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ReferralThresholdEngine

        init(store: any ReferralThresholdStore, validator: ReferralThresholdValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ReferralThresholdEngine) {
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
                throw Kit.Failure("referral threshold \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ReferralThresholdStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("referral threshold \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ReferralThresholdStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("referral threshold \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newReferralThresholdDesk(_ store: any ReferralThresholdStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ReferralThresholdDesk {
        return ReferralThresholdDesk(
            store: store,
            validator: defaultReferralThresholdValidator(),
            clock: clock,
            journal: [],
            engine: defaultReferralThresholdEngine(flags)
        )
    }
}
