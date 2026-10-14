import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves statement scores through their life cycle and keeps a journal of what it did.
    final class StatementScoreService {
        var store: any StatementScoreStore
        var validator: StatementScoreValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any StatementScoreStore, validator: StatementScoreValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("statement score \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StatementScoreStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("statement score \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StatementScoreStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newStatementScoreService(_ store: any StatementScoreStore, clock: any Kit.Clocks.Clock) -> StatementScoreService {
        return StatementScoreService(
            store: store,
            validator: defaultStatementScoreValidator(),
            clock: clock,
            journal: []
        )
    }
}
