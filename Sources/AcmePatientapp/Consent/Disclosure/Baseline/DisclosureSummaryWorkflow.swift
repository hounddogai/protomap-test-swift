import AcmePlatform
import Foundation

extension Consent {
    /// Moves disclosure summaries through their life cycle and keeps a journal of what it did.
    final class DisclosureSummaryDesk {
        var store: any DisclosureSummaryStore
        var validator: DisclosureSummaryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DisclosureSummaryEngine

        init(store: any DisclosureSummaryStore, validator: DisclosureSummaryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DisclosureSummaryEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("disclosure summary \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DisclosureSummaryStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("disclosure summary \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DisclosureSummaryStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("disclosure summary \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newDisclosureSummaryDesk(_ store: any DisclosureSummaryStore, clock: any Kit.Clocks.Clock) -> DisclosureSummaryDesk {
        return DisclosureSummaryDesk(
            store: store,
            validator: defaultDisclosureSummaryValidator(),
            clock: clock,
            journal: [],
            engine: defaultDisclosureSummaryEngine()
        )
    }
}
