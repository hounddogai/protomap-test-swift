import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves tiered task milestones through their life cycle and keeps a journal of what it did.
    final class TieredTaskMilestoneService {
        var store: any TieredTaskMilestoneStore
        var validator: TieredTaskMilestoneValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TieredTaskMilestoneEngine

        init(store: any TieredTaskMilestoneStore, validator: TieredTaskMilestoneValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TieredTaskMilestoneEngine) {
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
                throw Kit.Failure("tiered task milestone \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredTaskMilestoneStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered task milestone \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredTaskMilestoneStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered task milestone \(code) not found")
            }
            let result = engine.price(item)
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

    static func newTieredTaskMilestoneService(_ store: any TieredTaskMilestoneStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> TieredTaskMilestoneService {
        return TieredTaskMilestoneService(
            store: store,
            validator: defaultTieredTaskMilestoneValidator(),
            clock: clock,
            journal: [],
            engine: defaultTieredTaskMilestoneEngine(flags)
        )
    }
}
