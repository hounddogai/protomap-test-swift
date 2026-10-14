import AcmePlatform
import Foundation

extension Staffing {
    /// Moves acuity plan reviews through their life cycle and keeps a journal of what it did.
    final class AcuityPlanReviewDesk {
        var store: any AcuityPlanReviewStore
        var validator: AcuityPlanReviewValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AcuityPlanReviewEngine

        init(store: any AcuityPlanReviewStore, validator: AcuityPlanReviewValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AcuityPlanReviewEngine) {
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
                throw Kit.Failure("acuity plan review \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AcuityPlanReviewStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("acuity plan review \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AcuityPlanReviewStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("acuity plan review \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newAcuityPlanReviewDesk(_ store: any AcuityPlanReviewStore, clock: any Kit.Clocks.Clock) -> AcuityPlanReviewDesk {
        return AcuityPlanReviewDesk(
            store: store,
            validator: defaultAcuityPlanReviewValidator(),
            clock: clock,
            journal: [],
            engine: defaultAcuityPlanReviewEngine()
        )
    }
}
