import AcmePlatform
import Foundation

extension Staffing {
    /// Moves lenient skill mix assignments through their life cycle and keeps a journal of what it did.
    final class LenientSkillMixAssignmentWorkflow {
        var store: any LenientSkillMixAssignmentStore
        var validator: LenientSkillMixAssignmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any LenientSkillMixAssignmentStore, validator: LenientSkillMixAssignmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("lenient skill mix assignment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientSkillMixAssignmentStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient skill mix assignment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientSkillMixAssignmentStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
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

    static func newLenientSkillMixAssignmentWorkflow(_ store: any LenientSkillMixAssignmentStore, clock: any Kit.Clocks.Clock) -> LenientSkillMixAssignmentWorkflow {
        return LenientSkillMixAssignmentWorkflow(
            store: store,
            validator: defaultLenientSkillMixAssignmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
