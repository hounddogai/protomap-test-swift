import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves rolling goal batches through their life cycle and keeps a journal of what it did.
    final class RollingGoalBatchWorkflow {
        var store: any RollingGoalBatchStore
        var validator: RollingGoalBatchValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RollingGoalBatchStore, validator: RollingGoalBatchValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("rolling goal batch \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingGoalBatchStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling goal batch \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingGoalBatchStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
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

    static func newRollingGoalBatchWorkflow(_ store: any RollingGoalBatchStore, clock: any Kit.Clocks.Clock) -> RollingGoalBatchWorkflow {
        return RollingGoalBatchWorkflow(
            store: store,
            validator: defaultRollingGoalBatchValidator(),
            clock: clock,
            journal: []
        )
    }
}
