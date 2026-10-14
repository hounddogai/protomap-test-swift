import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves seasonal statement agreements through their life cycle and keeps a journal of what it did.
    final class SeasonalStatementAgreementWorkflow {
        var store: any SeasonalStatementAgreementStore
        var validator: SeasonalStatementAgreementValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SeasonalStatementAgreementEngine

        init(store: any SeasonalStatementAgreementStore, validator: SeasonalStatementAgreementValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SeasonalStatementAgreementEngine) {
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
                throw Kit.Failure("seasonal statement agreement \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalStatementAgreementStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal statement agreement \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalStatementAgreementStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal statement agreement \(code) not found")
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
                if item.expiresAt > cutoff {
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

    static func newSeasonalStatementAgreementWorkflow(_ store: any SeasonalStatementAgreementStore, clock: any Kit.Clocks.Clock) -> SeasonalStatementAgreementWorkflow {
        return SeasonalStatementAgreementWorkflow(
            store: store,
            validator: defaultSeasonalStatementAgreementValidator(),
            clock: clock,
            journal: [],
            engine: defaultSeasonalStatementAgreementEngine()
        )
    }
}
