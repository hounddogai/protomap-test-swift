import AcmePlatform
import Foundation

extension Referrals {
    /// Moves tiered follow up metrics through their life cycle and keeps a journal of what it did.
    final class TieredFollowUpMetricWorkflow {
        var store: any TieredFollowUpMetricStore
        var validator: TieredFollowUpMetricValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TieredFollowUpMetricEngine

        init(store: any TieredFollowUpMetricStore, validator: TieredFollowUpMetricValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TieredFollowUpMetricEngine) {
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
                throw Kit.Failure("tiered follow up metric \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredFollowUpMetricStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered follow up metric \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredFollowUpMetricStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered follow up metric \(code) not found")
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

    static func newTieredFollowUpMetricWorkflow(_ store: any TieredFollowUpMetricStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> TieredFollowUpMetricWorkflow {
        return TieredFollowUpMetricWorkflow(
            store: store,
            validator: defaultTieredFollowUpMetricValidator(),
            clock: clock,
            journal: [],
            engine: defaultTieredFollowUpMetricEngine(flags)
        )
    }
}
