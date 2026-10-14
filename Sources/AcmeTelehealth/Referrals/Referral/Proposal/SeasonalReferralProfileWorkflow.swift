import AcmePlatform
import Foundation

extension Referrals {
    /// Moves seasonal referral profiles through their life cycle and keeps a journal of what it did.
    final class SeasonalReferralProfileManager {
        var store: any SeasonalReferralProfileStore
        var validator: SeasonalReferralProfileValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SeasonalReferralProfileEngine

        init(store: any SeasonalReferralProfileStore, validator: SeasonalReferralProfileValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SeasonalReferralProfileEngine) {
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
                throw Kit.Failure("seasonal referral profile \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalReferralProfileStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal referral profile \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalReferralProfileStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal referral profile \(code) not found")
            }
            let result = engine.run(item)
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

    static func newSeasonalReferralProfileManager(_ store: any SeasonalReferralProfileStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> SeasonalReferralProfileManager {
        return SeasonalReferralProfileManager(
            store: store,
            validator: defaultSeasonalReferralProfileValidator(),
            clock: clock,
            journal: [],
            engine: defaultSeasonalReferralProfileEngine(flags)
        )
    }
}
