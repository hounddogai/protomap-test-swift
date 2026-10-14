import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves adaptive bed board reviews through their life cycle and keeps a journal of what it did.
    final class AdaptiveBedBoardReviewDesk {
        var store: any AdaptiveBedBoardReviewStore
        var validator: AdaptiveBedBoardReviewValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AdaptiveBedBoardReviewEngine

        init(store: any AdaptiveBedBoardReviewStore, validator: AdaptiveBedBoardReviewValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AdaptiveBedBoardReviewEngine) {
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
                throw Kit.Failure("adaptive bed board review \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptiveBedBoardReviewStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive bed board review \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptiveBedBoardReviewStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive bed board review \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newAdaptiveBedBoardReviewDesk(_ store: any AdaptiveBedBoardReviewStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> AdaptiveBedBoardReviewDesk {
        return AdaptiveBedBoardReviewDesk(
            store: store,
            validator: defaultAdaptiveBedBoardReviewValidator(),
            clock: clock,
            journal: [],
            engine: defaultAdaptiveBedBoardReviewEngine(flags)
        )
    }
}
