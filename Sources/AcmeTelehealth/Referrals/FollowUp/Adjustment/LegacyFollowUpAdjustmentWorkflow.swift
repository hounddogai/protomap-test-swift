import AcmePlatform
import Foundation

extension Referrals {
    /// Moves legacy follow up adjustments through their life cycle and keeps a journal of what it did.
    final class LegacyFollowUpAdjustmentWorkflow {
        var store: any LegacyFollowUpAdjustmentStore
        var validator: LegacyFollowUpAdjustmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LegacyFollowUpAdjustmentEngine

        init(store: any LegacyFollowUpAdjustmentStore, validator: LegacyFollowUpAdjustmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LegacyFollowUpAdjustmentEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy follow up adjustment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyFollowUpAdjustmentStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy follow up adjustment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyFollowUpAdjustmentStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy follow up adjustment \(code) not found")
            }
            let result = engine.run(item)
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

    static func newLegacyFollowUpAdjustmentWorkflow(_ store: any LegacyFollowUpAdjustmentStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> LegacyFollowUpAdjustmentWorkflow {
        return LegacyFollowUpAdjustmentWorkflow(
            store: store,
            validator: defaultLegacyFollowUpAdjustmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultLegacyFollowUpAdjustmentEngine(flags)
        )
    }
}
