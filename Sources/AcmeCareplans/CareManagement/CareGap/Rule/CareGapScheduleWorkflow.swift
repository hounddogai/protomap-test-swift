import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves care gap schedules through their life cycle and keeps a journal of what it did.
    final class CareGapScheduleDesk {
        var store: any CareGapScheduleStore
        var validator: CareGapScheduleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CareGapScheduleStore, validator: CareGapScheduleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("care gap schedule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CareGapScheduleStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care gap schedule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CareGapScheduleStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
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

    static func newCareGapScheduleDesk(_ store: any CareGapScheduleStore, clock: any Kit.Clocks.Clock) -> CareGapScheduleDesk {
        return CareGapScheduleDesk(
            store: store,
            validator: defaultCareGapScheduleValidator(),
            clock: clock,
            journal: []
        )
    }
}
