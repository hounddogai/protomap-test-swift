import AcmePlatform
import Foundation

extension Staffing {
    /// Moves skill mix profiles through their life cycle and keeps a journal of what it did.
    final class SkillMixProfileWorkflow {
        var store: any SkillMixProfileStore
        var validator: SkillMixProfileValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SkillMixProfileEngine

        init(store: any SkillMixProfileStore, validator: SkillMixProfileValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SkillMixProfileEngine) {
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
                throw Kit.Failure("skill mix profile \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SkillMixProfileStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("skill mix profile \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SkillMixProfileStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("skill mix profile \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newSkillMixProfileWorkflow(_ store: any SkillMixProfileStore, clock: any Kit.Clocks.Clock) -> SkillMixProfileWorkflow {
        return SkillMixProfileWorkflow(
            store: store,
            validator: defaultSkillMixProfileValidator(),
            clock: clock,
            journal: [],
            engine: defaultSkillMixProfileEngine()
        )
    }
}
