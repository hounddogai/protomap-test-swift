import AcmePlatform
import Foundation

extension Referrals {
    /// Moves weighted closure adjustments through their life cycle and keeps a journal of what it did.
    final class WeightedClosureAdjustmentWorkflow {
        var store: any WeightedClosureAdjustmentStore
        var validator: WeightedClosureAdjustmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any WeightedClosureAdjustmentStore, validator: WeightedClosureAdjustmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("weighted closure adjustment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedClosureAdjustmentStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted closure adjustment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedClosureAdjustmentStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newWeightedClosureAdjustmentWorkflow(_ store: any WeightedClosureAdjustmentStore, clock: any Kit.Clocks.Clock) -> WeightedClosureAdjustmentWorkflow {
        return WeightedClosureAdjustmentWorkflow(
            store: store,
            validator: defaultWeightedClosureAdjustmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
