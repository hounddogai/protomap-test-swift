import AcmePlatform
import Foundation

extension Labs {
    /// Moves reference range assignments through their life cycle and keeps a journal of what it did.
    final class ReferenceRangeAssignmentWorkflow {
        var store: any ReferenceRangeAssignmentStore
        var validator: ReferenceRangeAssignmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ReferenceRangeAssignmentStore, validator: ReferenceRangeAssignmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("reference range assignment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ReferenceRangeAssignmentStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("reference range assignment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ReferenceRangeAssignmentStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newReferenceRangeAssignmentWorkflow(_ store: any ReferenceRangeAssignmentStore, clock: any Kit.Clocks.Clock) -> ReferenceRangeAssignmentWorkflow {
        return ReferenceRangeAssignmentWorkflow(
            store: store,
            validator: defaultReferenceRangeAssignmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
