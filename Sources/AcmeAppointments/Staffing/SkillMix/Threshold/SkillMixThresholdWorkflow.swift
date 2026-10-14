import AcmePlatform
import Foundation

extension Staffing {
    /// Moves skill mix thresholds through their life cycle and keeps a journal of what it did.
    final class SkillMixThresholdWorkflow {
        var store: any SkillMixThresholdStore
        var validator: SkillMixThresholdValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any SkillMixThresholdStore, validator: SkillMixThresholdValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("skill mix threshold \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SkillMixThresholdStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("skill mix threshold \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SkillMixThresholdStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
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

    static func newSkillMixThresholdWorkflow(_ store: any SkillMixThresholdStore, clock: any Kit.Clocks.Clock) -> SkillMixThresholdWorkflow {
        return SkillMixThresholdWorkflow(
            store: store,
            validator: defaultSkillMixThresholdValidator(),
            clock: clock,
            journal: []
        )
    }
}
