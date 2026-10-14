import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves weighted denial reviews through their life cycle and keeps a journal of what it did.
    final class WeightedDenialReviewService {
        var store: any WeightedDenialReviewStore
        var validator: WeightedDenialReviewValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any WeightedDenialReviewStore, validator: WeightedDenialReviewValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted denial review \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedDenialReviewStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted denial review \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedDenialReviewStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newWeightedDenialReviewService(_ store: any WeightedDenialReviewStore, clock: any Kit.Clocks.Clock) -> WeightedDenialReviewService {
        return WeightedDenialReviewService(
            store: store,
            validator: defaultWeightedDenialReviewValidator(),
            clock: clock,
            journal: []
        )
    }
}
