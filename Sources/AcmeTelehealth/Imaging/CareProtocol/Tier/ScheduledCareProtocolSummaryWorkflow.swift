import AcmePlatform
import Foundation

extension Imaging {
    /// Moves scheduled care protocol summaries through their life cycle and keeps a journal of what it did.
    final class ScheduledCareProtocolSummaryDesk {
        var store: any ScheduledCareProtocolSummaryStore
        var validator: ScheduledCareProtocolSummaryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ScheduledCareProtocolSummaryEngine

        init(store: any ScheduledCareProtocolSummaryStore, validator: ScheduledCareProtocolSummaryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ScheduledCareProtocolSummaryEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled care protocol summary \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledCareProtocolSummaryStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled care protocol summary \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledCareProtocolSummaryStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled care protocol summary \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newScheduledCareProtocolSummaryDesk(_ store: any ScheduledCareProtocolSummaryStore, clock: any Kit.Clocks.Clock) -> ScheduledCareProtocolSummaryDesk {
        return ScheduledCareProtocolSummaryDesk(
            store: store,
            validator: defaultScheduledCareProtocolSummaryValidator(),
            clock: clock,
            journal: [],
            engine: defaultScheduledCareProtocolSummaryEngine()
        )
    }
}
