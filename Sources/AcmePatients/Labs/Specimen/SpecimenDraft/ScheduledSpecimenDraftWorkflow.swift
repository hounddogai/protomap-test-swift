import AcmePlatform
import Foundation

extension Labs {
    /// Moves scheduled specimen drafts through their life cycle and keeps a journal of what it did.
    final class ScheduledSpecimenDraftService {
        var store: any ScheduledSpecimenDraftStore
        var validator: ScheduledSpecimenDraftValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ScheduledSpecimenDraftStore, validator: ScheduledSpecimenDraftValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("scheduled specimen draft \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledSpecimenDraftStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled specimen draft \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledSpecimenDraftStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
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

    static func newScheduledSpecimenDraftService(_ store: any ScheduledSpecimenDraftStore, clock: any Kit.Clocks.Clock) -> ScheduledSpecimenDraftService {
        return ScheduledSpecimenDraftService(
            store: store,
            validator: defaultScheduledSpecimenDraftValidator(),
            clock: clock,
            journal: []
        )
    }
}
