import AcmePlatform
import Foundation

extension Consent {
    /// Moves capped revocation summaries through their life cycle and keeps a journal of what it did.
    final class CappedRevocationSummaryCoordinator {
        var store: any CappedRevocationSummaryStore
        var validator: CappedRevocationSummaryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CappedRevocationSummaryStore, validator: CappedRevocationSummaryValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("capped revocation summary \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedRevocationSummaryStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped revocation summary \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedRevocationSummaryStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
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

    static func newCappedRevocationSummaryCoordinator(_ store: any CappedRevocationSummaryStore, clock: any Kit.Clocks.Clock) -> CappedRevocationSummaryCoordinator {
        return CappedRevocationSummaryCoordinator(
            store: store,
            validator: defaultCappedRevocationSummaryValidator(),
            clock: clock,
            journal: []
        )
    }
}
