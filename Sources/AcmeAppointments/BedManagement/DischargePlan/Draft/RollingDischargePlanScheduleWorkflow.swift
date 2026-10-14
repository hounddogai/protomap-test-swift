import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves rolling discharge plan schedules through their life cycle and keeps a journal of what it did.
    final class RollingDischargePlanScheduleDesk {
        var store: any RollingDischargePlanScheduleStore
        var validator: RollingDischargePlanScheduleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RollingDischargePlanScheduleStore, validator: RollingDischargePlanScheduleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("rolling discharge plan schedule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingDischargePlanScheduleStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling discharge plan schedule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingDischargePlanScheduleStatus.cancelled)
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

    static func newRollingDischargePlanScheduleDesk(_ store: any RollingDischargePlanScheduleStore, clock: any Kit.Clocks.Clock) -> RollingDischargePlanScheduleDesk {
        return RollingDischargePlanScheduleDesk(
            store: store,
            validator: defaultRollingDischargePlanScheduleValidator(),
            clock: clock,
            journal: []
        )
    }
}
