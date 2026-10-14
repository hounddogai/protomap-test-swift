import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves statement rollups through their life cycle and keeps a journal of what it did.
    final class StatementRollupCoordinator {
        var store: any StatementRollupStore
        var validator: StatementRollupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: StatementRollupEngine

        init(store: any StatementRollupStore, validator: StatementRollupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: StatementRollupEngine) {
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
                throw Kit.Failure("statement rollup \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StatementRollupStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("statement rollup \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StatementRollupStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("statement rollup \(code) not found")
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

    static func newStatementRollupCoordinator(_ store: any StatementRollupStore, clock: any Kit.Clocks.Clock) -> StatementRollupCoordinator {
        return StatementRollupCoordinator(
            store: store,
            validator: defaultStatementRollupValidator(),
            clock: clock,
            journal: [],
            engine: defaultStatementRollupEngine()
        )
    }
}
