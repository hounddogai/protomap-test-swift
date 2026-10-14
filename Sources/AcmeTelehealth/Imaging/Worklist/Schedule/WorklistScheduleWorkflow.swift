import AcmePlatform
import Foundation

extension Imaging {
    /// Moves worklist schedules through their life cycle and keeps a journal of what it did.
    final class WorklistScheduleCoordinator {
        var store: any WorklistScheduleStore
        var validator: WorklistScheduleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any WorklistScheduleStore, validator: WorklistScheduleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("worklist schedule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WorklistScheduleStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("worklist schedule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WorklistScheduleStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
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

    static func newWorklistScheduleCoordinator(_ store: any WorklistScheduleStore, clock: any Kit.Clocks.Clock) -> WorklistScheduleCoordinator {
        return WorklistScheduleCoordinator(
            store: store,
            validator: defaultWorklistScheduleValidator(),
            clock: clock,
            journal: []
        )
    }
}
