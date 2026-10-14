import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves tiered recall summaries through their life cycle and keeps a journal of what it did.
    final class TieredRecallSummaryCoordinator {
        var store: any TieredRecallSummaryStore
        var validator: TieredRecallSummaryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TieredRecallSummaryEngine

        init(store: any TieredRecallSummaryStore, validator: TieredRecallSummaryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TieredRecallSummaryEngine) {
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
                throw Kit.Failure("tiered recall summary \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredRecallSummaryStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered recall summary \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredRecallSummaryStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered recall summary \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newTieredRecallSummaryCoordinator(_ store: any TieredRecallSummaryStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> TieredRecallSummaryCoordinator {
        return TieredRecallSummaryCoordinator(
            store: store,
            validator: defaultTieredRecallSummaryValidator(),
            clock: clock,
            journal: [],
            engine: defaultTieredRecallSummaryEngine(flags)
        )
    }
}
