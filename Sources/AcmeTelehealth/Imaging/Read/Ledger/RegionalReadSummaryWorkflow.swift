import AcmePlatform
import Foundation

extension Imaging {
    /// Moves regional read summaries through their life cycle and keeps a journal of what it did.
    final class RegionalReadSummaryDesk {
        var store: any RegionalReadSummaryStore
        var validator: RegionalReadSummaryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RegionalReadSummaryStore, validator: RegionalReadSummaryValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("regional read summary \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalReadSummaryStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional read summary \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalReadSummaryStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newRegionalReadSummaryDesk(_ store: any RegionalReadSummaryStore, clock: any Kit.Clocks.Clock) -> RegionalReadSummaryDesk {
        return RegionalReadSummaryDesk(
            store: store,
            validator: defaultRegionalReadSummaryValidator(),
            clock: clock,
            journal: []
        )
    }
}
