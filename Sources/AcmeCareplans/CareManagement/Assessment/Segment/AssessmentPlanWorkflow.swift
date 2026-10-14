import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves assessment plans through their life cycle and keeps a journal of what it did.
    final class AssessmentPlanService {
        var store: any AssessmentPlanStore
        var validator: AssessmentPlanValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AssessmentPlanEngine

        init(store: any AssessmentPlanStore, validator: AssessmentPlanValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AssessmentPlanEngine) {
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
                throw Kit.Failure("assessment plan \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AssessmentPlanStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("assessment plan \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AssessmentPlanStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("assessment plan \(code) not found")
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

    static func newAssessmentPlanService(_ store: any AssessmentPlanStore, clock: any Kit.Clocks.Clock) -> AssessmentPlanService {
        return AssessmentPlanService(
            store: store,
            validator: defaultAssessmentPlanValidator(),
            clock: clock,
            journal: [],
            engine: defaultAssessmentPlanEngine()
        )
    }
}
