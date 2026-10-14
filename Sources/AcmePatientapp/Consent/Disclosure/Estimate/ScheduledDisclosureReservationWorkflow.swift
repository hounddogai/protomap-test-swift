import AcmePlatform
import Foundation

extension Consent {
    /// Moves scheduled disclosure reservations through their life cycle and keeps a journal of what it did.
    final class ScheduledDisclosureReservationWorkflow {
        var store: any ScheduledDisclosureReservationStore
        var validator: ScheduledDisclosureReservationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ScheduledDisclosureReservationStore, validator: ScheduledDisclosureReservationValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("scheduled disclosure reservation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledDisclosureReservationStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled disclosure reservation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledDisclosureReservationStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
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

    static func newScheduledDisclosureReservationWorkflow(_ store: any ScheduledDisclosureReservationStore, clock: any Kit.Clocks.Clock) -> ScheduledDisclosureReservationWorkflow {
        return ScheduledDisclosureReservationWorkflow(
            store: store,
            validator: defaultScheduledDisclosureReservationValidator(),
            clock: clock,
            journal: []
        )
    }
}
