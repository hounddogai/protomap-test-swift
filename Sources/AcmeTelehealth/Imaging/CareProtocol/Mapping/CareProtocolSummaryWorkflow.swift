import AcmePlatform
import Foundation

extension Imaging {
    /// Moves care protocol summaries through their life cycle and keeps a journal of what it did.
    final class CareProtocolSummaryDesk {
        var store: any CareProtocolSummaryStore
        var validator: CareProtocolSummaryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CareProtocolSummaryEngine

        init(store: any CareProtocolSummaryStore, validator: CareProtocolSummaryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CareProtocolSummaryEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care protocol summary \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CareProtocolSummaryStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care protocol summary \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CareProtocolSummaryStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("care protocol summary \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newCareProtocolSummaryDesk(_ store: any CareProtocolSummaryStore, clock: any Kit.Clocks.Clock) -> CareProtocolSummaryDesk {
        return CareProtocolSummaryDesk(
            store: store,
            validator: defaultCareProtocolSummaryValidator(),
            clock: clock,
            journal: [],
            engine: defaultCareProtocolSummaryEngine()
        )
    }
}
