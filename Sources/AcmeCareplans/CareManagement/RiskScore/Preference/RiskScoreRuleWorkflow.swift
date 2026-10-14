import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves risk score rules through their life cycle and keeps a journal of what it did.
    final class RiskScoreRuleManager {
        var store: any RiskScoreRuleStore
        var validator: RiskScoreRuleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RiskScoreRuleEngine

        init(store: any RiskScoreRuleStore, validator: RiskScoreRuleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RiskScoreRuleEngine) {
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
                throw Kit.Failure("risk score rule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RiskScoreRuleStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("risk score rule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RiskScoreRuleStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("risk score rule \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newRiskScoreRuleManager(_ store: any RiskScoreRuleStore, clock: any Kit.Clocks.Clock) -> RiskScoreRuleManager {
        return RiskScoreRuleManager(
            store: store,
            validator: defaultRiskScoreRuleValidator(),
            clock: clock,
            journal: [],
            engine: defaultRiskScoreRuleEngine()
        )
    }
}
