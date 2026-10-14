import AcmePlatform
import Foundation

extension Referrals {
    /// Moves weighted eligibility windows through their life cycle and keeps a journal of what it did.
    final class WeightedEligibilityWindowCoordinator {
        var store: any WeightedEligibilityWindowStore
        var validator: WeightedEligibilityWindowValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any WeightedEligibilityWindowStore, validator: WeightedEligibilityWindowValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("weighted eligibility window \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedEligibilityWindowStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted eligibility window \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedEligibilityWindowStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
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

    static func newWeightedEligibilityWindowCoordinator(_ store: any WeightedEligibilityWindowStore, clock: any Kit.Clocks.Clock) -> WeightedEligibilityWindowCoordinator {
        return WeightedEligibilityWindowCoordinator(
            store: store,
            validator: defaultWeightedEligibilityWindowValidator(),
            clock: clock,
            journal: []
        )
    }
}
