import AcmePlatform
import Foundation

extension Referrals {
    /// Moves strict slot checkpoints through their life cycle and keeps a journal of what it did.
    final class StrictSlotCheckpointWorkflow {
        var store: any StrictSlotCheckpointStore
        var validator: StrictSlotCheckpointValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any StrictSlotCheckpointStore, validator: StrictSlotCheckpointValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("strict slot checkpoint \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictSlotCheckpointStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict slot checkpoint \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictSlotCheckpointStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newStrictSlotCheckpointWorkflow(_ store: any StrictSlotCheckpointStore, clock: any Kit.Clocks.Clock) -> StrictSlotCheckpointWorkflow {
        return StrictSlotCheckpointWorkflow(
            store: store,
            validator: defaultStrictSlotCheckpointValidator(),
            clock: clock,
            journal: []
        )
    }
}
