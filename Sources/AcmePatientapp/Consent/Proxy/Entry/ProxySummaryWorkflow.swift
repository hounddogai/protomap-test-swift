import AcmePlatform
import Foundation

extension Consent {
    /// Moves proxy summaries through their life cycle and keeps a journal of what it did.
    final class ProxySummaryDesk {
        var store: any ProxySummaryStore
        var validator: ProxySummaryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ProxySummaryEngine

        init(store: any ProxySummaryStore, validator: ProxySummaryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ProxySummaryEngine) {
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
                throw Kit.Failure("proxy summary \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ProxySummaryStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("proxy summary \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ProxySummaryStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("proxy summary \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newProxySummaryDesk(_ store: any ProxySummaryStore, clock: any Kit.Clocks.Clock) -> ProxySummaryDesk {
        return ProxySummaryDesk(
            store: store,
            validator: defaultProxySummaryValidator(),
            clock: clock,
            journal: [],
            engine: defaultProxySummaryEngine()
        )
    }
}
