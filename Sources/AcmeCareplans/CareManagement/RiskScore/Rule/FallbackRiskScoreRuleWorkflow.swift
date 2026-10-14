import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves fallback risk score rules through their life cycle and keeps a journal of what it did.
    final class FallbackRiskScoreRuleService {
        var store: any FallbackRiskScoreRuleStore
        var validator: FallbackRiskScoreRuleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FallbackRiskScoreRuleEngine

        init(store: any FallbackRiskScoreRuleStore, validator: FallbackRiskScoreRuleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FallbackRiskScoreRuleEngine) {
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
                throw Kit.Failure("fallback risk score rule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackRiskScoreRuleStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback risk score rule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackRiskScoreRuleStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback risk score rule \(code) not found")
            }
            let result = engine.price(item)
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

    static func newFallbackRiskScoreRuleService(_ store: any FallbackRiskScoreRuleStore, clock: any Kit.Clocks.Clock) -> FallbackRiskScoreRuleService {
        return FallbackRiskScoreRuleService(
            store: store,
            validator: defaultFallbackRiskScoreRuleValidator(),
            clock: clock,
            journal: [],
            engine: defaultFallbackRiskScoreRuleEngine()
        )
    }
}
