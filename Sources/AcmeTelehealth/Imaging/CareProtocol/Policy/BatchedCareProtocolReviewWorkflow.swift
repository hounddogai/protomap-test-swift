import AcmePlatform
import Foundation

extension Imaging {
    /// Moves batched care protocol reviews through their life cycle and keeps a journal of what it did.
    final class BatchedCareProtocolReviewDesk {
        var store: any BatchedCareProtocolReviewStore
        var validator: BatchedCareProtocolReviewValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BatchedCareProtocolReviewEngine

        init(store: any BatchedCareProtocolReviewStore, validator: BatchedCareProtocolReviewValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BatchedCareProtocolReviewEngine) {
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
                throw Kit.Failure("batched care protocol review \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedCareProtocolReviewStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched care protocol review \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedCareProtocolReviewStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched care protocol review \(code) not found")
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

    static func newBatchedCareProtocolReviewDesk(_ store: any BatchedCareProtocolReviewStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> BatchedCareProtocolReviewDesk {
        return BatchedCareProtocolReviewDesk(
            store: store,
            validator: defaultBatchedCareProtocolReviewValidator(),
            clock: clock,
            journal: [],
            engine: defaultBatchedCareProtocolReviewEngine(flags)
        )
    }
}
