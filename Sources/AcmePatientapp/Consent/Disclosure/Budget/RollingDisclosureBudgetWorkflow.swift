import AcmePlatform
import Foundation

extension Consent {
    /// Moves rolling disclosure budgets through their life cycle and keeps a journal of what it did.
    final class RollingDisclosureBudgetWorkflow {
        var store: any RollingDisclosureBudgetStore
        var validator: RollingDisclosureBudgetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RollingDisclosureBudgetEngine

        init(store: any RollingDisclosureBudgetStore, validator: RollingDisclosureBudgetValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RollingDisclosureBudgetEngine) {
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
                throw Kit.Failure("rolling disclosure budget \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingDisclosureBudgetStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling disclosure budget \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingDisclosureBudgetStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling disclosure budget \(code) not found")
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
                if item.startsAt > cutoff {
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

    static func newRollingDisclosureBudgetWorkflow(_ store: any RollingDisclosureBudgetStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RollingDisclosureBudgetWorkflow {
        return RollingDisclosureBudgetWorkflow(
            store: store,
            validator: defaultRollingDisclosureBudgetValidator(),
            clock: clock,
            journal: [],
            engine: defaultRollingDisclosureBudgetEngine(flags)
        )
    }
}
