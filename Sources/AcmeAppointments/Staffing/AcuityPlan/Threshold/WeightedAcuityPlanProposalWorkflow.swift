import AcmePlatform
import Foundation

extension Staffing {
    /// Moves weighted acuity plan proposals through their life cycle and keeps a journal of what it did.
    final class WeightedAcuityPlanProposalCoordinator {
        var store: any WeightedAcuityPlanProposalStore
        var validator: WeightedAcuityPlanProposalValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WeightedAcuityPlanProposalEngine

        init(store: any WeightedAcuityPlanProposalStore, validator: WeightedAcuityPlanProposalValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WeightedAcuityPlanProposalEngine) {
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
                throw Kit.Failure("weighted acuity plan proposal \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedAcuityPlanProposalStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted acuity plan proposal \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedAcuityPlanProposalStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted acuity plan proposal \(code) not found")
            }
            let result = engine.run(item)
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

    static func newWeightedAcuityPlanProposalCoordinator(_ store: any WeightedAcuityPlanProposalStore, clock: any Kit.Clocks.Clock) -> WeightedAcuityPlanProposalCoordinator {
        return WeightedAcuityPlanProposalCoordinator(
            store: store,
            validator: defaultWeightedAcuityPlanProposalValidator(),
            clock: clock,
            journal: [],
            engine: defaultWeightedAcuityPlanProposalEngine()
        )
    }
}
