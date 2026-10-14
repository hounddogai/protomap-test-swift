import AcmePlatform
import Foundation

extension Consent {
    /// Moves scheduled language cycles through their life cycle and keeps a journal of what it did.
    final class ScheduledLanguageCycleDesk {
        var store: any ScheduledLanguageCycleStore
        var validator: ScheduledLanguageCycleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ScheduledLanguageCycleStore, validator: ScheduledLanguageCycleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("scheduled language cycle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledLanguageCycleStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled language cycle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledLanguageCycleStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newScheduledLanguageCycleDesk(_ store: any ScheduledLanguageCycleStore, clock: any Kit.Clocks.Clock) -> ScheduledLanguageCycleDesk {
        return ScheduledLanguageCycleDesk(
            store: store,
            validator: defaultScheduledLanguageCycleValidator(),
            clock: clock,
            journal: []
        )
    }
}
