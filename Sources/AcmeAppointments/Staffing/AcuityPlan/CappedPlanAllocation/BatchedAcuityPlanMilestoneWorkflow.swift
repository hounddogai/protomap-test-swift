import AcmePlatform
import Foundation

extension Staffing {
    /// Moves batched acuity plan milestones through their life cycle and keeps a journal of what it did.
    final class BatchedAcuityPlanMilestoneCoordinator {
        var store: any BatchedAcuityPlanMilestoneStore
        var validator: BatchedAcuityPlanMilestoneValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BatchedAcuityPlanMilestoneEngine

        init(store: any BatchedAcuityPlanMilestoneStore, validator: BatchedAcuityPlanMilestoneValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BatchedAcuityPlanMilestoneEngine) {
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
                throw Kit.Failure("batched acuity plan milestone \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedAcuityPlanMilestoneStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched acuity plan milestone \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedAcuityPlanMilestoneStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched acuity plan milestone \(code) not found")
            }
            let result = engine.run(item)
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

    static func newBatchedAcuityPlanMilestoneCoordinator(_ store: any BatchedAcuityPlanMilestoneStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> BatchedAcuityPlanMilestoneCoordinator {
        return BatchedAcuityPlanMilestoneCoordinator(
            store: store,
            validator: defaultBatchedAcuityPlanMilestoneValidator(),
            clock: clock,
            journal: [],
            engine: defaultBatchedAcuityPlanMilestoneEngine(flags)
        )
    }
}
