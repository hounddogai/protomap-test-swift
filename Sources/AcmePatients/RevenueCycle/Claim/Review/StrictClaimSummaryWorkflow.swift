import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves strict claim summaries through their life cycle and keeps a journal of what it did.
    final class StrictClaimSummaryService {
        var store: any StrictClaimSummaryStore
        var validator: StrictClaimSummaryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any StrictClaimSummaryStore, validator: StrictClaimSummaryValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("strict claim summary \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictClaimSummaryStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict claim summary \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictClaimSummaryStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newStrictClaimSummaryService(_ store: any StrictClaimSummaryStore, clock: any Kit.Clocks.Clock) -> StrictClaimSummaryService {
        return StrictClaimSummaryService(
            store: store,
            validator: defaultStrictClaimSummaryValidator(),
            clock: clock,
            journal: []
        )
    }
}
