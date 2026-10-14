import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves denial schedules through their life cycle and keeps a journal of what it did.
    final class DenialScheduleCoordinator {
        var store: any DenialScheduleStore
        var validator: DenialScheduleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any DenialScheduleStore, validator: DenialScheduleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("denial schedule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DenialScheduleStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("denial schedule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DenialScheduleStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newDenialScheduleCoordinator(_ store: any DenialScheduleStore, clock: any Kit.Clocks.Clock) -> DenialScheduleCoordinator {
        return DenialScheduleCoordinator(
            store: store,
            validator: defaultDenialScheduleValidator(),
            clock: clock,
            journal: []
        )
    }
}
