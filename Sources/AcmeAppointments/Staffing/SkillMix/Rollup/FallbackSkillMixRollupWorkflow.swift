import AcmePlatform
import Foundation

extension Staffing {
    /// Moves fallback skill mix rollups through their life cycle and keeps a journal of what it did.
    final class FallbackSkillMixRollupManager {
        var store: any FallbackSkillMixRollupStore
        var validator: FallbackSkillMixRollupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FallbackSkillMixRollupEngine

        init(store: any FallbackSkillMixRollupStore, validator: FallbackSkillMixRollupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FallbackSkillMixRollupEngine) {
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
                throw Kit.Failure("fallback skill mix rollup \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackSkillMixRollupStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback skill mix rollup \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackSkillMixRollupStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback skill mix rollup \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newFallbackSkillMixRollupManager(_ store: any FallbackSkillMixRollupStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> FallbackSkillMixRollupManager {
        return FallbackSkillMixRollupManager(
            store: store,
            validator: defaultFallbackSkillMixRollupValidator(),
            clock: clock,
            journal: [],
            engine: defaultFallbackSkillMixRollupEngine(flags)
        )
    }
}
