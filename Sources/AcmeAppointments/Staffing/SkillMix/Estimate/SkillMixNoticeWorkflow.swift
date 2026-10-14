import AcmePlatform
import Foundation

extension Staffing {
    /// Moves skill mix notices through their life cycle and keeps a journal of what it did.
    final class SkillMixNoticeCoordinator {
        var store: any SkillMixNoticeStore
        var validator: SkillMixNoticeValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SkillMixNoticeEngine

        init(store: any SkillMixNoticeStore, validator: SkillMixNoticeValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SkillMixNoticeEngine) {
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
                throw Kit.Failure("skill mix notice \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SkillMixNoticeStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("skill mix notice \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SkillMixNoticeStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("skill mix notice \(code) not found")
            }
            let result = engine.price(item)
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

    static func newSkillMixNoticeCoordinator(_ store: any SkillMixNoticeStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> SkillMixNoticeCoordinator {
        return SkillMixNoticeCoordinator(
            store: store,
            validator: defaultSkillMixNoticeValidator(),
            clock: clock,
            journal: [],
            engine: defaultSkillMixNoticeEngine(flags)
        )
    }
}
