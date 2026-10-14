import AcmePlatform
import Foundation

extension Consent {
    /// Moves language summaries through their life cycle and keeps a journal of what it did.
    final class LanguageSummaryDesk {
        var store: any LanguageSummaryStore
        var validator: LanguageSummaryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any LanguageSummaryStore, validator: LanguageSummaryValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("language summary \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LanguageSummaryStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("language summary \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LanguageSummaryStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
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

    static func newLanguageSummaryDesk(_ store: any LanguageSummaryStore, clock: any Kit.Clocks.Clock) -> LanguageSummaryDesk {
        return LanguageSummaryDesk(
            store: store,
            validator: defaultLanguageSummaryValidator(),
            clock: clock,
            journal: []
        )
    }
}
