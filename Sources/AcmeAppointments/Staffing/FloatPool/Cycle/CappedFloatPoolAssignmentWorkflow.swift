import AcmePlatform
import Foundation

extension Staffing {
    /// Moves capped float pool assignments through their life cycle and keeps a journal of what it did.
    final class CappedFloatPoolAssignmentWorkflow {
        var store: any CappedFloatPoolAssignmentStore
        var validator: CappedFloatPoolAssignmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CappedFloatPoolAssignmentStore, validator: CappedFloatPoolAssignmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("capped float pool assignment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedFloatPoolAssignmentStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped float pool assignment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedFloatPoolAssignmentStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newCappedFloatPoolAssignmentWorkflow(_ store: any CappedFloatPoolAssignmentStore, clock: any Kit.Clocks.Clock) -> CappedFloatPoolAssignmentWorkflow {
        return CappedFloatPoolAssignmentWorkflow(
            store: store,
            validator: defaultCappedFloatPoolAssignmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
