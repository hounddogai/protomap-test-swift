import AcmePlatform
import Foundation

extension Staffing {
    /// Moves shift checkpoints through their life cycle and keeps a journal of what it did.
    final class ShiftCheckpointWorkflow {
        var store: any ShiftCheckpointStore
        var validator: ShiftCheckpointValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ShiftCheckpointStore, validator: ShiftCheckpointValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("shift checkpoint \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ShiftCheckpointStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("shift checkpoint \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ShiftCheckpointStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newShiftCheckpointWorkflow(_ store: any ShiftCheckpointStore, clock: any Kit.Clocks.Clock) -> ShiftCheckpointWorkflow {
        return ShiftCheckpointWorkflow(
            store: store,
            validator: defaultShiftCheckpointValidator(),
            clock: clock,
            journal: []
        )
    }
}
