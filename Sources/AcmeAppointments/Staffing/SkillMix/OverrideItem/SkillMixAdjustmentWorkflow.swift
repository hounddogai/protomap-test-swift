import AcmePlatform
import Foundation

extension Staffing {
    /// Moves skill mix adjustments through their life cycle and keeps a journal of what it did.
    final class SkillMixAdjustmentManager {
        var store: any SkillMixAdjustmentStore
        var validator: SkillMixAdjustmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any SkillMixAdjustmentStore, validator: SkillMixAdjustmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("skill mix adjustment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SkillMixAdjustmentStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("skill mix adjustment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SkillMixAdjustmentStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
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

    static func newSkillMixAdjustmentManager(_ store: any SkillMixAdjustmentStore, clock: any Kit.Clocks.Clock) -> SkillMixAdjustmentManager {
        return SkillMixAdjustmentManager(
            store: store,
            validator: defaultSkillMixAdjustmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
