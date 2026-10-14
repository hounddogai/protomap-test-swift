import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves weighted order set policies through their life cycle and keeps a journal of what it did.
    final class WeightedOrderSetPolicyCoordinator {
        var store: any WeightedOrderSetPolicyStore
        var validator: WeightedOrderSetPolicyValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WeightedOrderSetPolicyEngine

        init(store: any WeightedOrderSetPolicyStore, validator: WeightedOrderSetPolicyValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WeightedOrderSetPolicyEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted order set policy \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedOrderSetPolicyStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted order set policy \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedOrderSetPolicyStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted order set policy \(code) not found")
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
                if item.endsAt > cutoff {
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

    static func newWeightedOrderSetPolicyCoordinator(_ store: any WeightedOrderSetPolicyStore, clock: any Kit.Clocks.Clock) -> WeightedOrderSetPolicyCoordinator {
        return WeightedOrderSetPolicyCoordinator(
            store: store,
            validator: defaultWeightedOrderSetPolicyValidator(),
            clock: clock,
            journal: [],
            engine: defaultWeightedOrderSetPolicyEngine()
        )
    }
}
