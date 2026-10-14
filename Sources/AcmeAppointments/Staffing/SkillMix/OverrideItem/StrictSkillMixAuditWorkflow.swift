import AcmePlatform
import Foundation

extension Staffing {
    /// Moves strict skill mix audits through their life cycle and keeps a journal of what it did.
    final class StrictSkillMixAuditService {
        var store: any StrictSkillMixAuditStore
        var validator: StrictSkillMixAuditValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any StrictSkillMixAuditStore, validator: StrictSkillMixAuditValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict skill mix audit \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictSkillMixAuditStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict skill mix audit \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictSkillMixAuditStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
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

    static func newStrictSkillMixAuditService(_ store: any StrictSkillMixAuditStore, clock: any Kit.Clocks.Clock) -> StrictSkillMixAuditService {
        return StrictSkillMixAuditService(
            store: store,
            validator: defaultStrictSkillMixAuditValidator(),
            clock: clock,
            journal: []
        )
    }
}
