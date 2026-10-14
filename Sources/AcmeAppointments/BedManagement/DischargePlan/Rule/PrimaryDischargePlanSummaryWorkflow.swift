import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves primary discharge plan summaries through their life cycle and keeps a journal of what it did.
    final class PrimaryDischargePlanSummaryCoordinator {
        var store: any PrimaryDischargePlanSummaryStore
        var validator: PrimaryDischargePlanSummaryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrimaryDischargePlanSummaryEngine

        init(store: any PrimaryDischargePlanSummaryStore, validator: PrimaryDischargePlanSummaryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrimaryDischargePlanSummaryEngine) {
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
                throw Kit.Failure("primary discharge plan summary \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryDischargePlanSummaryStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary discharge plan summary \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryDischargePlanSummaryStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary discharge plan summary \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newPrimaryDischargePlanSummaryCoordinator(_ store: any PrimaryDischargePlanSummaryStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PrimaryDischargePlanSummaryCoordinator {
        return PrimaryDischargePlanSummaryCoordinator(
            store: store,
            validator: defaultPrimaryDischargePlanSummaryValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrimaryDischargePlanSummaryEngine(flags)
        )
    }
}
