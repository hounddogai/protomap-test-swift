import AcmePlatform
import Foundation

extension Referrals {
    /// Moves slot checkpoints through their life cycle and keeps a journal of what it did.
    final class SlotCheckpointWorkflow {
        var store: any SlotCheckpointStore
        var validator: SlotCheckpointValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any SlotCheckpointStore, validator: SlotCheckpointValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("slot checkpoint \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SlotCheckpointStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("slot checkpoint \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SlotCheckpointStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newSlotCheckpointWorkflow(_ store: any SlotCheckpointStore, clock: any Kit.Clocks.Clock) -> SlotCheckpointWorkflow {
        return SlotCheckpointWorkflow(
            store: store,
            validator: defaultSlotCheckpointValidator(),
            clock: clock,
            journal: []
        )
    }
}
