import AcmePlatform
import Foundation

extension Imaging {
    /// Moves adaptive care protocol budgets through their life cycle and keeps a journal of what it did.
    final class AdaptiveCareProtocolBudgetWorkflow {
        var store: any AdaptiveCareProtocolBudgetStore
        var validator: AdaptiveCareProtocolBudgetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AdaptiveCareProtocolBudgetEngine

        init(store: any AdaptiveCareProtocolBudgetStore, validator: AdaptiveCareProtocolBudgetValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AdaptiveCareProtocolBudgetEngine) {
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
                throw Kit.Failure("adaptive care protocol budget \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptiveCareProtocolBudgetStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive care protocol budget \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptiveCareProtocolBudgetStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive care protocol budget \(code) not found")
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

    static func newAdaptiveCareProtocolBudgetWorkflow(_ store: any AdaptiveCareProtocolBudgetStore, clock: any Kit.Clocks.Clock) -> AdaptiveCareProtocolBudgetWorkflow {
        return AdaptiveCareProtocolBudgetWorkflow(
            store: store,
            validator: defaultAdaptiveCareProtocolBudgetValidator(),
            clock: clock,
            journal: [],
            engine: defaultAdaptiveCareProtocolBudgetEngine()
        )
    }
}
