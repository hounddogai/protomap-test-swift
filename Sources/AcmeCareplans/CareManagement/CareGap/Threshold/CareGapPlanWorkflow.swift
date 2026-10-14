import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves care gap plans through their life cycle and keeps a journal of what it did.
    final class CareGapPlanService {
        var store: any CareGapPlanStore
        var validator: CareGapPlanValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CareGapPlanEngine

        init(store: any CareGapPlanStore, validator: CareGapPlanValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CareGapPlanEngine) {
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
                throw Kit.Failure("care gap plan \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CareGapPlanStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care gap plan \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CareGapPlanStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("care gap plan \(code) not found")
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

    static func newCareGapPlanService(_ store: any CareGapPlanStore, clock: any Kit.Clocks.Clock) -> CareGapPlanService {
        return CareGapPlanService(
            store: store,
            validator: defaultCareGapPlanValidator(),
            clock: clock,
            journal: [],
            engine: defaultCareGapPlanEngine()
        )
    }
}
