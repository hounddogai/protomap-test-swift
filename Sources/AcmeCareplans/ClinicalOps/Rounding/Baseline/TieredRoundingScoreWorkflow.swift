import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves tiered rounding scores through their life cycle and keeps a journal of what it did.
    final class TieredRoundingScoreService {
        var store: any TieredRoundingScoreStore
        var validator: TieredRoundingScoreValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any TieredRoundingScoreStore, validator: TieredRoundingScoreValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("tiered rounding score \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredRoundingScoreStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered rounding score \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredRoundingScoreStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newTieredRoundingScoreService(_ store: any TieredRoundingScoreStore, clock: any Kit.Clocks.Clock) -> TieredRoundingScoreService {
        return TieredRoundingScoreService(
            store: store,
            validator: defaultTieredRoundingScoreValidator(),
            clock: clock,
            journal: []
        )
    }
}
