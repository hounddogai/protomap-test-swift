import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves strict cleaning summaries through their life cycle and keeps a journal of what it did.
    final class StrictCleaningSummaryCoordinator {
        var store: any StrictCleaningSummaryStore
        var validator: StrictCleaningSummaryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: StrictCleaningSummaryEngine

        init(store: any StrictCleaningSummaryStore, validator: StrictCleaningSummaryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: StrictCleaningSummaryEngine) {
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
                throw Kit.Failure("strict cleaning summary \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictCleaningSummaryStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict cleaning summary \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictCleaningSummaryStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict cleaning summary \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newStrictCleaningSummaryCoordinator(_ store: any StrictCleaningSummaryStore, clock: any Kit.Clocks.Clock) -> StrictCleaningSummaryCoordinator {
        return StrictCleaningSummaryCoordinator(
            store: store,
            validator: defaultStrictCleaningSummaryValidator(),
            clock: clock,
            journal: [],
            engine: defaultStrictCleaningSummaryEngine()
        )
    }
}
