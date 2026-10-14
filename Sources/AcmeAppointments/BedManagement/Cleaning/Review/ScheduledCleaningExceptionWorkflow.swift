import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves scheduled cleaning exceptions through their life cycle and keeps a journal of what it did.
    final class ScheduledCleaningExceptionCoordinator {
        var store: any ScheduledCleaningExceptionStore
        var validator: ScheduledCleaningExceptionValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ScheduledCleaningExceptionStore, validator: ScheduledCleaningExceptionValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("scheduled cleaning exception \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledCleaningExceptionStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled cleaning exception \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledCleaningExceptionStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
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

    static func newScheduledCleaningExceptionCoordinator(_ store: any ScheduledCleaningExceptionStore, clock: any Kit.Clocks.Clock) -> ScheduledCleaningExceptionCoordinator {
        return ScheduledCleaningExceptionCoordinator(
            store: store,
            validator: defaultScheduledCleaningExceptionValidator(),
            clock: clock,
            journal: []
        )
    }
}
