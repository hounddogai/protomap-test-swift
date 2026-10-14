import AcmePlatform
import Foundation

extension Staffing {
    /// Moves skill mix audits through their life cycle and keeps a journal of what it did.
    final class SkillMixAuditCoordinator {
        var store: any SkillMixAuditStore
        var validator: SkillMixAuditValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SkillMixAuditEngine

        init(store: any SkillMixAuditStore, validator: SkillMixAuditValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SkillMixAuditEngine) {
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
                throw Kit.Failure("skill mix audit \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SkillMixAuditStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("skill mix audit \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SkillMixAuditStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("skill mix audit \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
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

    static func newSkillMixAuditCoordinator(_ store: any SkillMixAuditStore, clock: any Kit.Clocks.Clock) -> SkillMixAuditCoordinator {
        return SkillMixAuditCoordinator(
            store: store,
            validator: defaultSkillMixAuditValidator(),
            clock: clock,
            journal: [],
            engine: defaultSkillMixAuditEngine()
        )
    }
}
