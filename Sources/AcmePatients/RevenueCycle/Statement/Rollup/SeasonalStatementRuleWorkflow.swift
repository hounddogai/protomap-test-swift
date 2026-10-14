import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves seasonal statement rules through their life cycle and keeps a journal of what it did.
    final class SeasonalStatementRuleManager {
        var store: any SeasonalStatementRuleStore
        var validator: SeasonalStatementRuleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SeasonalStatementRuleEngine

        init(store: any SeasonalStatementRuleStore, validator: SeasonalStatementRuleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SeasonalStatementRuleEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal statement rule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalStatementRuleStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal statement rule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalStatementRuleStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal statement rule \(code) not found")
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

    static func newSeasonalStatementRuleManager(_ store: any SeasonalStatementRuleStore, clock: any Kit.Clocks.Clock) -> SeasonalStatementRuleManager {
        return SeasonalStatementRuleManager(
            store: store,
            validator: defaultSeasonalStatementRuleValidator(),
            clock: clock,
            journal: [],
            engine: defaultSeasonalStatementRuleEngine()
        )
    }
}
