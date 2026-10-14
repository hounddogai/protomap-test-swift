import AcmePlatform
import Foundation

extension Staffing {
    /// Moves tiered acuity plan milestones through their life cycle and keeps a journal of what it did.
    final class TieredAcuityPlanMilestoneService {
        var store: any TieredAcuityPlanMilestoneStore
        var validator: TieredAcuityPlanMilestoneValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TieredAcuityPlanMilestoneEngine

        init(store: any TieredAcuityPlanMilestoneStore, validator: TieredAcuityPlanMilestoneValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TieredAcuityPlanMilestoneEngine) {
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
                throw Kit.Failure("tiered acuity plan milestone \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredAcuityPlanMilestoneStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered acuity plan milestone \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredAcuityPlanMilestoneStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered acuity plan milestone \(code) not found")
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
                if item.createdAt > cutoff {
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

    static func newTieredAcuityPlanMilestoneService(_ store: any TieredAcuityPlanMilestoneStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> TieredAcuityPlanMilestoneService {
        return TieredAcuityPlanMilestoneService(
            store: store,
            validator: defaultTieredAcuityPlanMilestoneValidator(),
            clock: clock,
            journal: [],
            engine: defaultTieredAcuityPlanMilestoneEngine(flags)
        )
    }
}
