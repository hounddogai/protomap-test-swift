import AcmePlatform
import Foundation

extension Staffing {
    /// Moves scheduled float pool assignments through their life cycle and keeps a journal of what it did.
    final class ScheduledFloatPoolAssignmentCoordinator {
        var store: any ScheduledFloatPoolAssignmentStore
        var validator: ScheduledFloatPoolAssignmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ScheduledFloatPoolAssignmentStore, validator: ScheduledFloatPoolAssignmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("scheduled float pool assignment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledFloatPoolAssignmentStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled float pool assignment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledFloatPoolAssignmentStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
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

    static func newScheduledFloatPoolAssignmentCoordinator(_ store: any ScheduledFloatPoolAssignmentStore, clock: any Kit.Clocks.Clock) -> ScheduledFloatPoolAssignmentCoordinator {
        return ScheduledFloatPoolAssignmentCoordinator(
            store: store,
            validator: defaultScheduledFloatPoolAssignmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
