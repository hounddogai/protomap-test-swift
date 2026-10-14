import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves batched authorization baselines through their life cycle and keeps a journal of what it did.
    final class BatchedAuthorizationBaselineDesk {
        var store: any BatchedAuthorizationBaselineStore
        var validator: BatchedAuthorizationBaselineValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BatchedAuthorizationBaselineEngine

        init(store: any BatchedAuthorizationBaselineStore, validator: BatchedAuthorizationBaselineValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BatchedAuthorizationBaselineEngine) {
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
                throw Kit.Failure("batched authorization baseline \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedAuthorizationBaselineStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched authorization baseline \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedAuthorizationBaselineStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched authorization baseline \(code) not found")
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

    static func newBatchedAuthorizationBaselineDesk(_ store: any BatchedAuthorizationBaselineStore, clock: any Kit.Clocks.Clock) -> BatchedAuthorizationBaselineDesk {
        return BatchedAuthorizationBaselineDesk(
            store: store,
            validator: defaultBatchedAuthorizationBaselineValidator(),
            clock: clock,
            journal: [],
            engine: defaultBatchedAuthorizationBaselineEngine()
        )
    }
}
