import AcmePlatform
import Foundation

extension Consent {
    /// Moves language scores through their life cycle and keeps a journal of what it did.
    final class LanguageScoreDesk {
        var store: any LanguageScoreStore
        var validator: LanguageScoreValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any LanguageScoreStore, validator: LanguageScoreValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("language score \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LanguageScoreStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("language score \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LanguageScoreStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newLanguageScoreDesk(_ store: any LanguageScoreStore, clock: any Kit.Clocks.Clock) -> LanguageScoreDesk {
        return LanguageScoreDesk(store: store, validator: defaultLanguageScoreValidator(), clock: clock, journal: [])
    }
}
