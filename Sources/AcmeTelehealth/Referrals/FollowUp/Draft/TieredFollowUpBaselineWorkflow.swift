import AcmePlatform
import Foundation

extension Referrals {
    /// Moves tiered follow up baselines through their life cycle and keeps a journal of what it did.
    final class TieredFollowUpBaselineCoordinator {
        var store: any TieredFollowUpBaselineStore
        var validator: TieredFollowUpBaselineValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TieredFollowUpBaselineEngine

        init(store: any TieredFollowUpBaselineStore, validator: TieredFollowUpBaselineValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TieredFollowUpBaselineEngine) {
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
                throw Kit.Failure("tiered follow up baseline \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredFollowUpBaselineStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered follow up baseline \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredFollowUpBaselineStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered follow up baseline \(code) not found")
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

    static func newTieredFollowUpBaselineCoordinator(_ store: any TieredFollowUpBaselineStore, clock: any Kit.Clocks.Clock) -> TieredFollowUpBaselineCoordinator {
        return TieredFollowUpBaselineCoordinator(
            store: store,
            validator: defaultTieredFollowUpBaselineValidator(),
            clock: clock,
            journal: [],
            engine: defaultTieredFollowUpBaselineEngine()
        )
    }
}
