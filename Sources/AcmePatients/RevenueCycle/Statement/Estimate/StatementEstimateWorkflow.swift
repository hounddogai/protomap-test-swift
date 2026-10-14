import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves statement estimates through their life cycle and keeps a journal of what it did.
    final class StatementEstimateWorkflow {
        var store: any StatementEstimateStore
        var validator: StatementEstimateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any StatementEstimateStore, validator: StatementEstimateValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("statement estimate \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StatementEstimateStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("statement estimate \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StatementEstimateStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newStatementEstimateWorkflow(_ store: any StatementEstimateStore, clock: any Kit.Clocks.Clock) -> StatementEstimateWorkflow {
        return StatementEstimateWorkflow(
            store: store,
            validator: defaultStatementEstimateValidator(),
            clock: clock,
            journal: []
        )
    }
}
