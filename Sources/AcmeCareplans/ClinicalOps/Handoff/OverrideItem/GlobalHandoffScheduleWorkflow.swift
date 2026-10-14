import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves global handoff schedules through their life cycle and keeps a journal of what it did.
    final class GlobalHandoffScheduleDesk {
        var store: any GlobalHandoffScheduleStore
        var validator: GlobalHandoffScheduleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any GlobalHandoffScheduleStore, validator: GlobalHandoffScheduleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("global handoff schedule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalHandoffScheduleStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global handoff schedule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalHandoffScheduleStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
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

    static func newGlobalHandoffScheduleDesk(_ store: any GlobalHandoffScheduleStore, clock: any Kit.Clocks.Clock) -> GlobalHandoffScheduleDesk {
        return GlobalHandoffScheduleDesk(
            store: store,
            validator: defaultGlobalHandoffScheduleValidator(),
            clock: clock,
            journal: []
        )
    }
}
