import AcmePlatform
import Foundation

extension Staffing {
    /// Moves capped skill mix cycles through their life cycle and keeps a journal of what it did.
    final class CappedSkillMixCycleDesk {
        var store: any CappedSkillMixCycleStore
        var validator: CappedSkillMixCycleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CappedSkillMixCycleEngine

        init(store: any CappedSkillMixCycleStore, validator: CappedSkillMixCycleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CappedSkillMixCycleEngine) {
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
                throw Kit.Failure("capped skill mix cycle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedSkillMixCycleStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped skill mix cycle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedSkillMixCycleStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped skill mix cycle \(code) not found")
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

    static func newCappedSkillMixCycleDesk(_ store: any CappedSkillMixCycleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CappedSkillMixCycleDesk {
        return CappedSkillMixCycleDesk(
            store: store,
            validator: defaultCappedSkillMixCycleValidator(),
            clock: clock,
            journal: [],
            engine: defaultCappedSkillMixCycleEngine(flags)
        )
    }
}
