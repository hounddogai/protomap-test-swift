import AcmePlatform
import Foundation

extension Labs {
    /// Moves courier drafts through their life cycle and keeps a journal of what it did.
    final class CourierDraftService {
        var store: any CourierDraftStore
        var validator: CourierDraftValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CourierDraftStore, validator: CourierDraftValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("courier draft \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CourierDraftStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("courier draft \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CourierDraftStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newCourierDraftService(_ store: any CourierDraftStore, clock: any Kit.Clocks.Clock) -> CourierDraftService {
        return CourierDraftService(
            store: store,
            validator: defaultCourierDraftValidator(),
            clock: clock,
            journal: []
        )
    }
}
