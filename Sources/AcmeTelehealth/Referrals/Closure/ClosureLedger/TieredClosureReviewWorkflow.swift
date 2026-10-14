import AcmePlatform
import Foundation

extension Referrals {
    /// Moves tiered closure reviews through their life cycle and keeps a journal of what it did.
    final class TieredClosureReviewDesk {
        var store: any TieredClosureReviewStore
        var validator: TieredClosureReviewValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TieredClosureReviewEngine

        init(store: any TieredClosureReviewStore, validator: TieredClosureReviewValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TieredClosureReviewEngine) {
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
                throw Kit.Failure("tiered closure review \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredClosureReviewStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered closure review \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredClosureReviewStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered closure review \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newTieredClosureReviewDesk(_ store: any TieredClosureReviewStore, clock: any Kit.Clocks.Clock) -> TieredClosureReviewDesk {
        return TieredClosureReviewDesk(
            store: store,
            validator: defaultTieredClosureReviewValidator(),
            clock: clock,
            journal: [],
            engine: defaultTieredClosureReviewEngine()
        )
    }
}
