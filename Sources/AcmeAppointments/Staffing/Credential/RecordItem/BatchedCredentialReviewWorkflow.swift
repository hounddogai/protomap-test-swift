import AcmePlatform
import Foundation

extension Staffing {
    /// Moves batched credential reviews through their life cycle and keeps a journal of what it did.
    final class BatchedCredentialReviewService {
        var store: any BatchedCredentialReviewStore
        var validator: BatchedCredentialReviewValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BatchedCredentialReviewEngine

        init(store: any BatchedCredentialReviewStore, validator: BatchedCredentialReviewValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BatchedCredentialReviewEngine) {
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
                throw Kit.Failure("batched credential review \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedCredentialReviewStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched credential review \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedCredentialReviewStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched credential review \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newBatchedCredentialReviewService(_ store: any BatchedCredentialReviewStore, clock: any Kit.Clocks.Clock) -> BatchedCredentialReviewService {
        return BatchedCredentialReviewService(
            store: store,
            validator: defaultBatchedCredentialReviewValidator(),
            clock: clock,
            journal: [],
            engine: defaultBatchedCredentialReviewEngine()
        )
    }
}
