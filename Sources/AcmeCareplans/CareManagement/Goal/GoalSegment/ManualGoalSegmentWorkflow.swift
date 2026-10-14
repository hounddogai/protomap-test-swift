import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves manual goal segments through their life cycle and keeps a journal of what it did.
    final class ManualGoalSegmentWorkflow {
        var store: any ManualGoalSegmentStore
        var validator: ManualGoalSegmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ManualGoalSegmentStore, validator: ManualGoalSegmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("manual goal segment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualGoalSegmentStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual goal segment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualGoalSegmentStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
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

    static func newManualGoalSegmentWorkflow(_ store: any ManualGoalSegmentStore, clock: any Kit.Clocks.Clock) -> ManualGoalSegmentWorkflow {
        return ManualGoalSegmentWorkflow(
            store: store,
            validator: defaultManualGoalSegmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
