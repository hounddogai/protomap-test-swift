import AcmePlatform
import Foundation

extension Consent {
    /// Moves lenient proxy budgets through their life cycle and keeps a journal of what it did.
    final class LenientProxyBudgetWorkflow {
        var store: any LenientProxyBudgetStore
        var validator: LenientProxyBudgetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LenientProxyBudgetEngine

        init(store: any LenientProxyBudgetStore, validator: LenientProxyBudgetValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LenientProxyBudgetEngine) {
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
                throw Kit.Failure("lenient proxy budget \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientProxyBudgetStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient proxy budget \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientProxyBudgetStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient proxy budget \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newLenientProxyBudgetWorkflow(_ store: any LenientProxyBudgetStore, clock: any Kit.Clocks.Clock) -> LenientProxyBudgetWorkflow {
        return LenientProxyBudgetWorkflow(
            store: store,
            validator: defaultLenientProxyBudgetValidator(),
            clock: clock,
            journal: [],
            engine: defaultLenientProxyBudgetEngine()
        )
    }
}
