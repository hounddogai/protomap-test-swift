import AcmePlatform
import Foundation

extension Staffing {
    /// Moves default skill mix scores through their life cycle and keeps a journal of what it did.
    final class DefaultSkillMixScoreDesk {
        var store: any DefaultSkillMixScoreStore
        var validator: DefaultSkillMixScoreValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DefaultSkillMixScoreEngine

        init(store: any DefaultSkillMixScoreStore, validator: DefaultSkillMixScoreValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DefaultSkillMixScoreEngine) {
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
                throw Kit.Failure("default skill mix score \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultSkillMixScoreStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default skill mix score \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultSkillMixScoreStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("default skill mix score \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newDefaultSkillMixScoreDesk(_ store: any DefaultSkillMixScoreStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> DefaultSkillMixScoreDesk {
        return DefaultSkillMixScoreDesk(
            store: store,
            validator: defaultDefaultSkillMixScoreValidator(),
            clock: clock,
            journal: [],
            engine: defaultDefaultSkillMixScoreEngine(flags)
        )
    }
}
