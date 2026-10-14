import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves risk score summaries through their life cycle and keeps a journal of what it did.
    final class RiskScoreSummaryCoordinator {
        var store: any RiskScoreSummaryStore
        var validator: RiskScoreSummaryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RiskScoreSummaryEngine

        init(store: any RiskScoreSummaryStore, validator: RiskScoreSummaryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RiskScoreSummaryEngine) {
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
                throw Kit.Failure("risk score summary \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RiskScoreSummaryStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("risk score summary \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RiskScoreSummaryStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("risk score summary \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newRiskScoreSummaryCoordinator(_ store: any RiskScoreSummaryStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RiskScoreSummaryCoordinator {
        return RiskScoreSummaryCoordinator(
            store: store,
            validator: defaultRiskScoreSummaryValidator(),
            clock: clock,
            journal: [],
            engine: defaultRiskScoreSummaryEngine(flags)
        )
    }
}
