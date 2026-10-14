import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves risk score baselines through their life cycle and keeps a journal of what it did.
    final class RiskScoreBaselineWorkflow {
        var store: any RiskScoreBaselineStore
        var validator: RiskScoreBaselineValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RiskScoreBaselineEngine

        init(store: any RiskScoreBaselineStore, validator: RiskScoreBaselineValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RiskScoreBaselineEngine) {
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
                throw Kit.Failure("risk score baseline \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RiskScoreBaselineStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("risk score baseline \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RiskScoreBaselineStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("risk score baseline \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newRiskScoreBaselineWorkflow(_ store: any RiskScoreBaselineStore, clock: any Kit.Clocks.Clock) -> RiskScoreBaselineWorkflow {
        return RiskScoreBaselineWorkflow(
            store: store,
            validator: defaultRiskScoreBaselineValidator(),
            clock: clock,
            journal: [],
            engine: defaultRiskScoreBaselineEngine()
        )
    }
}
