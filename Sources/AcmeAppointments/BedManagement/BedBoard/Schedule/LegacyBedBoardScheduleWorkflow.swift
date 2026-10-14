import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves legacy bed board schedules through their life cycle and keeps a journal of what it did.
    final class LegacyBedBoardScheduleService {
        var store: any LegacyBedBoardScheduleStore
        var validator: LegacyBedBoardScheduleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any LegacyBedBoardScheduleStore, validator: LegacyBedBoardScheduleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("legacy bed board schedule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyBedBoardScheduleStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy bed board schedule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyBedBoardScheduleStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
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

    static func newLegacyBedBoardScheduleService(_ store: any LegacyBedBoardScheduleStore, clock: any Kit.Clocks.Clock) -> LegacyBedBoardScheduleService {
        return LegacyBedBoardScheduleService(
            store: store,
            validator: defaultLegacyBedBoardScheduleValidator(),
            clock: clock,
            journal: []
        )
    }
}
