import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves weighted claim overrides through their life cycle and keeps a journal of what it did.
    final class WeightedClaimOverrideCoordinator {
        var store: any WeightedClaimOverrideStore
        var validator: WeightedClaimOverrideValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any WeightedClaimOverrideStore, validator: WeightedClaimOverrideValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("weighted claim override \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedClaimOverrideStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted claim override \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedClaimOverrideStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
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

    static func newWeightedClaimOverrideCoordinator(_ store: any WeightedClaimOverrideStore, clock: any Kit.Clocks.Clock) -> WeightedClaimOverrideCoordinator {
        return WeightedClaimOverrideCoordinator(
            store: store,
            validator: defaultWeightedClaimOverrideValidator(),
            clock: clock,
            journal: []
        )
    }
}
