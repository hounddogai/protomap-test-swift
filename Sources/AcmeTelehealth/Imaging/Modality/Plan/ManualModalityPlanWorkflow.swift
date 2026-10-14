import AcmePlatform
import Foundation

extension Imaging {
    /// Moves manual modality plans through their life cycle and keeps a journal of what it did.
    final class ManualModalityPlanService {
        var store: any ManualModalityPlanStore
        var validator: ManualModalityPlanValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ManualModalityPlanEngine

        init(store: any ManualModalityPlanStore, validator: ManualModalityPlanValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ManualModalityPlanEngine) {
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
                throw Kit.Failure("manual modality plan \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualModalityPlanStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual modality plan \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualModalityPlanStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual modality plan \(code) not found")
            }
            let result = engine.price(item)
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

    static func newManualModalityPlanService(_ store: any ManualModalityPlanStore, clock: any Kit.Clocks.Clock) -> ManualModalityPlanService {
        return ManualModalityPlanService(
            store: store,
            validator: defaultManualModalityPlanValidator(),
            clock: clock,
            journal: [],
            engine: defaultManualModalityPlanEngine()
        )
    }
}
