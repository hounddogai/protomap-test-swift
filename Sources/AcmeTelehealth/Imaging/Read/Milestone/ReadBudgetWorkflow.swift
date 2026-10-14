import AcmePlatform
import Foundation

extension Imaging {
    /// Moves read budgets through their life cycle and keeps a journal of what it did.
    final class ReadBudgetWorkflow {
        var store: any ReadBudgetStore
        var validator: ReadBudgetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ReadBudgetEngine

        init(store: any ReadBudgetStore, validator: ReadBudgetValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ReadBudgetEngine) {
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
                throw Kit.Failure("read budget \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ReadBudgetStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("read budget \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ReadBudgetStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("read budget \(code) not found")
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

    static func newReadBudgetWorkflow(_ store: any ReadBudgetStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ReadBudgetWorkflow {
        return ReadBudgetWorkflow(
            store: store,
            validator: defaultReadBudgetValidator(),
            clock: clock,
            journal: [],
            engine: defaultReadBudgetEngine(flags)
        )
    }
}
