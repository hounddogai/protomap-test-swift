import AcmePlatform
import Foundation

extension Labs {
    /// Moves courier milestones through their life cycle and keeps a journal of what it did.
    final class CourierMilestoneCoordinator {
        var store: any CourierMilestoneStore
        var validator: CourierMilestoneValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CourierMilestoneStore, validator: CourierMilestoneValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("courier milestone \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CourierMilestoneStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("courier milestone \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CourierMilestoneStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
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

    static func newCourierMilestoneCoordinator(_ store: any CourierMilestoneStore, clock: any Kit.Clocks.Clock) -> CourierMilestoneCoordinator {
        return CourierMilestoneCoordinator(
            store: store,
            validator: defaultCourierMilestoneValidator(),
            clock: clock,
            journal: []
        )
    }
}
