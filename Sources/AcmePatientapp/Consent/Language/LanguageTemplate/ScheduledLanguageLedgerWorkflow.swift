import AcmePlatform
import Foundation

extension Consent {
    /// Moves scheduled language ledgers through their life cycle and keeps a journal of what it did.
    final class ScheduledLanguageLedgerManager {
        var store: any ScheduledLanguageLedgerStore
        var validator: ScheduledLanguageLedgerValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ScheduledLanguageLedgerStore, validator: ScheduledLanguageLedgerValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("scheduled language ledger \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledLanguageLedgerStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled language ledger \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledLanguageLedgerStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
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

    static func newScheduledLanguageLedgerManager(_ store: any ScheduledLanguageLedgerStore, clock: any Kit.Clocks.Clock) -> ScheduledLanguageLedgerManager {
        return ScheduledLanguageLedgerManager(
            store: store,
            validator: defaultScheduledLanguageLedgerValidator(),
            clock: clock,
            journal: []
        )
    }
}
