import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves weighted charge policies through their life cycle and keeps a journal of what it did.
    final class WeightedChargePolicyDesk {
        var store: any WeightedChargePolicyStore
        var validator: WeightedChargePolicyValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any WeightedChargePolicyStore, validator: WeightedChargePolicyValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted charge policy \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedChargePolicyStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted charge policy \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedChargePolicyStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newWeightedChargePolicyDesk(_ store: any WeightedChargePolicyStore, clock: any Kit.Clocks.Clock) -> WeightedChargePolicyDesk {
        return WeightedChargePolicyDesk(
            store: store,
            validator: defaultWeightedChargePolicyValidator(),
            clock: clock,
            journal: []
        )
    }
}
