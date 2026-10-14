import AcmePlatform
import Foundation

extension Staffing {
    /// Moves skill mix overrides through their life cycle and keeps a journal of what it did.
    final class SkillMixOverrideManager {
        var store: any SkillMixOverrideStore
        var validator: SkillMixOverrideValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SkillMixOverrideEngine

        init(store: any SkillMixOverrideStore, validator: SkillMixOverrideValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SkillMixOverrideEngine) {
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
                throw Kit.Failure("skill mix override \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SkillMixOverrideStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("skill mix override \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SkillMixOverrideStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("skill mix override \(code) not found")
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

    static func newSkillMixOverrideManager(_ store: any SkillMixOverrideStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> SkillMixOverrideManager {
        return SkillMixOverrideManager(
            store: store,
            validator: defaultSkillMixOverrideValidator(),
            clock: clock,
            journal: [],
            engine: defaultSkillMixOverrideEngine(flags)
        )
    }
}
