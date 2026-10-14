import AcmePlatform
import Foundation

extension Imaging {
    /// Moves seasonal study reviews through their life cycle and keeps a journal of what it did.
    final class SeasonalStudyReviewService {
        var store: any SeasonalStudyReviewStore
        var validator: SeasonalStudyReviewValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any SeasonalStudyReviewStore, validator: SeasonalStudyReviewValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("seasonal study review \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalStudyReviewStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal study review \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalStudyReviewStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
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

    static func newSeasonalStudyReviewService(_ store: any SeasonalStudyReviewStore, clock: any Kit.Clocks.Clock) -> SeasonalStudyReviewService {
        return SeasonalStudyReviewService(
            store: store,
            validator: defaultSeasonalStudyReviewValidator(),
            clock: clock,
            journal: []
        )
    }
}
