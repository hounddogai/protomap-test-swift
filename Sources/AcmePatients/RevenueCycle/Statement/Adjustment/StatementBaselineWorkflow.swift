import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves statement baselines through their life cycle and keeps a journal of what it did.
    final class StatementBaselineCoordinator {
        var store: any StatementBaselineStore
        var validator: StatementBaselineValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any StatementBaselineStore, validator: StatementBaselineValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("statement baseline \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StatementBaselineStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("statement baseline \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StatementBaselineStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
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

    static func newStatementBaselineCoordinator(_ store: any StatementBaselineStore, clock: any Kit.Clocks.Clock) -> StatementBaselineCoordinator {
        return StatementBaselineCoordinator(
            store: store,
            validator: defaultStatementBaselineValidator(),
            clock: clock,
            journal: []
        )
    }
}
