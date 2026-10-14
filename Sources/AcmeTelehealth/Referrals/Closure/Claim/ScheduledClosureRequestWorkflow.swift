import AcmePlatform
import Foundation

extension Referrals {
    /// Moves scheduled closure requests through their life cycle and keeps a journal of what it did.
    final class ScheduledClosureRequestCoordinator {
        var store: any ScheduledClosureRequestStore
        var validator: ScheduledClosureRequestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ScheduledClosureRequestStore, validator: ScheduledClosureRequestValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("scheduled closure request \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledClosureRequestStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled closure request \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledClosureRequestStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newScheduledClosureRequestCoordinator(_ store: any ScheduledClosureRequestStore, clock: any Kit.Clocks.Clock) -> ScheduledClosureRequestCoordinator {
        return ScheduledClosureRequestCoordinator(
            store: store,
            validator: defaultScheduledClosureRequestValidator(),
            clock: clock,
            journal: []
        )
    }
}
