import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves recall reviews through their life cycle and keeps a journal of what it did.
    final class RecallReviewService {
        var store: any RecallReviewStore
        var validator: RecallReviewValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RecallReviewEngine

        init(store: any RecallReviewStore, validator: RecallReviewValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RecallReviewEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("recall review \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RecallReviewStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("recall review \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RecallReviewStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("recall review \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newRecallReviewService(_ store: any RecallReviewStore, clock: any Kit.Clocks.Clock) -> RecallReviewService {
        return RecallReviewService(
            store: store,
            validator: defaultRecallReviewValidator(),
            clock: clock,
            journal: [],
            engine: defaultRecallReviewEngine()
        )
    }
}
