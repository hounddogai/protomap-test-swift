import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves adaptive recall reviews through their life cycle and keeps a journal of what it did.
    final class AdaptiveRecallReviewManager {
        var store: any AdaptiveRecallReviewStore
        var validator: AdaptiveRecallReviewValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AdaptiveRecallReviewEngine

        init(store: any AdaptiveRecallReviewStore, validator: AdaptiveRecallReviewValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AdaptiveRecallReviewEngine) {
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
                throw Kit.Failure("adaptive recall review \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptiveRecallReviewStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive recall review \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptiveRecallReviewStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive recall review \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newAdaptiveRecallReviewManager(_ store: any AdaptiveRecallReviewStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> AdaptiveRecallReviewManager {
        return AdaptiveRecallReviewManager(
            store: store,
            validator: defaultAdaptiveRecallReviewValidator(),
            clock: clock,
            journal: [],
            engine: defaultAdaptiveRecallReviewEngine(flags)
        )
    }
}
