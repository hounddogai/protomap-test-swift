import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves weighted goal digests through their life cycle and keeps a journal of what it did.
    final class WeightedGoalDigestManager {
        var store: any WeightedGoalDigestStore
        var validator: WeightedGoalDigestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any WeightedGoalDigestStore, validator: WeightedGoalDigestValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted goal digest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedGoalDigestStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted goal digest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedGoalDigestStatus.withdrawn)
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

    static func newWeightedGoalDigestManager(_ store: any WeightedGoalDigestStore, clock: any Kit.Clocks.Clock) -> WeightedGoalDigestManager {
        return WeightedGoalDigestManager(
            store: store,
            validator: defaultWeightedGoalDigestValidator(),
            clock: clock,
            journal: []
        )
    }
}
