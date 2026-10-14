import AcmePlatform
import Foundation

extension Referrals {
    /// Moves weighted follow up rules through their life cycle and keeps a journal of what it did.
    final class WeightedFollowUpRuleCoordinator {
        var store: any WeightedFollowUpRuleStore
        var validator: WeightedFollowUpRuleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any WeightedFollowUpRuleStore, validator: WeightedFollowUpRuleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("weighted follow up rule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedFollowUpRuleStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted follow up rule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedFollowUpRuleStatus.expired)
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

    static func newWeightedFollowUpRuleCoordinator(_ store: any WeightedFollowUpRuleStore, clock: any Kit.Clocks.Clock) -> WeightedFollowUpRuleCoordinator {
        return WeightedFollowUpRuleCoordinator(
            store: store,
            validator: defaultWeightedFollowUpRuleValidator(),
            clock: clock,
            journal: []
        )
    }
}
