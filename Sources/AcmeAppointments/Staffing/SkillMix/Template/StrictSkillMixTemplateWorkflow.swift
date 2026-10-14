import AcmePlatform
import Foundation

extension Staffing {
    /// Moves strict skill mix templates through their life cycle and keeps a journal of what it did.
    final class StrictSkillMixTemplateDesk {
        var store: any StrictSkillMixTemplateStore
        var validator: StrictSkillMixTemplateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: StrictSkillMixTemplateEngine

        init(store: any StrictSkillMixTemplateStore, validator: StrictSkillMixTemplateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: StrictSkillMixTemplateEngine) {
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
                throw Kit.Failure("strict skill mix template \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictSkillMixTemplateStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict skill mix template \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictSkillMixTemplateStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict skill mix template \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newStrictSkillMixTemplateDesk(_ store: any StrictSkillMixTemplateStore, clock: any Kit.Clocks.Clock) -> StrictSkillMixTemplateDesk {
        return StrictSkillMixTemplateDesk(
            store: store,
            validator: defaultStrictSkillMixTemplateValidator(),
            clock: clock,
            journal: [],
            engine: defaultStrictSkillMixTemplateEngine()
        )
    }
}
