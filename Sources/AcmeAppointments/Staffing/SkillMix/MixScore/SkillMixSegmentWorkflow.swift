import AcmePlatform
import Foundation

extension Staffing {
    /// Moves skill mix segments through their life cycle and keeps a journal of what it did.
    final class SkillMixSegmentService {
        var store: any SkillMixSegmentStore
        var validator: SkillMixSegmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SkillMixSegmentEngine

        init(store: any SkillMixSegmentStore, validator: SkillMixSegmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SkillMixSegmentEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("skill mix segment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SkillMixSegmentStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("skill mix segment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SkillMixSegmentStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("skill mix segment \(code) not found")
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

    static func newSkillMixSegmentService(_ store: any SkillMixSegmentStore, clock: any Kit.Clocks.Clock) -> SkillMixSegmentService {
        return SkillMixSegmentService(
            store: store,
            validator: defaultSkillMixSegmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultSkillMixSegmentEngine()
        )
    }
}
