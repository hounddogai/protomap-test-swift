import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves statement plans through their life cycle and keeps a journal of what it did.
    final class StatementPlanWorkflow {
        var store: any StatementPlanStore
        var validator: StatementPlanValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: StatementPlanEngine

        init(store: any StatementPlanStore, validator: StatementPlanValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: StatementPlanEngine) {
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
                throw Kit.Failure("statement plan \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StatementPlanStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("statement plan \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StatementPlanStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("statement plan \(code) not found")
            }
            let result = engine.price(item)
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

    static func newStatementPlanWorkflow(_ store: any StatementPlanStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> StatementPlanWorkflow {
        return StatementPlanWorkflow(
            store: store,
            validator: defaultStatementPlanValidator(),
            clock: clock,
            journal: [],
            engine: defaultStatementPlanEngine(flags)
        )
    }
}
