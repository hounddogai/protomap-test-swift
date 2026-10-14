import AcmePlatform
import Foundation

extension Labs {
    /// Moves reference range schedules through their life cycle and keeps a journal of what it did.
    final class ReferenceRangeScheduleWorkflow {
        var store: any ReferenceRangeScheduleStore
        var validator: ReferenceRangeScheduleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ReferenceRangeScheduleStore, validator: ReferenceRangeScheduleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("reference range schedule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ReferenceRangeScheduleStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("reference range schedule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ReferenceRangeScheduleStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
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

    static func newReferenceRangeScheduleWorkflow(_ store: any ReferenceRangeScheduleStore, clock: any Kit.Clocks.Clock) -> ReferenceRangeScheduleWorkflow {
        return ReferenceRangeScheduleWorkflow(
            store: store,
            validator: defaultReferenceRangeScheduleValidator(),
            clock: clock,
            journal: []
        )
    }
}
