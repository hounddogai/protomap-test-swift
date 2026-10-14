import AcmePlatform
import Foundation

extension Labs {
    /// Moves lenient reference range schedules through their life cycle and keeps a journal of what it did.
    final class LenientReferenceRangeScheduleWorkflow {
        var store: any LenientReferenceRangeScheduleStore
        var validator: LenientReferenceRangeScheduleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any LenientReferenceRangeScheduleStore, validator: LenientReferenceRangeScheduleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("lenient reference range schedule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientReferenceRangeScheduleStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient reference range schedule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientReferenceRangeScheduleStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newLenientReferenceRangeScheduleWorkflow(_ store: any LenientReferenceRangeScheduleStore, clock: any Kit.Clocks.Clock) -> LenientReferenceRangeScheduleWorkflow {
        return LenientReferenceRangeScheduleWorkflow(
            store: store,
            validator: defaultLenientReferenceRangeScheduleValidator(),
            clock: clock,
            journal: []
        )
    }
}
