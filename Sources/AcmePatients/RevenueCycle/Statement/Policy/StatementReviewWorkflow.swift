import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves statement reviews through their life cycle and keeps a journal of what it did.
    final class StatementReviewManager {
        var store: any StatementReviewStore
        var validator: StatementReviewValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: StatementReviewEngine

        init(store: any StatementReviewStore, validator: StatementReviewValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: StatementReviewEngine) {
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
                throw Kit.Failure("statement review \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StatementReviewStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("statement review \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StatementReviewStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("statement review \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newStatementReviewManager(_ store: any StatementReviewStore, clock: any Kit.Clocks.Clock) -> StatementReviewManager {
        return StatementReviewManager(
            store: store,
            validator: defaultStatementReviewValidator(),
            clock: clock,
            journal: [],
            engine: defaultStatementReviewEngine()
        )
    }
}
