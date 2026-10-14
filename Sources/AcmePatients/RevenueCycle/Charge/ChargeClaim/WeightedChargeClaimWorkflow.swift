import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves weighted charge claims through their life cycle and keeps a journal of what it did.
    final class WeightedChargeClaimWorkflow {
        var store: any WeightedChargeClaimStore
        var validator: WeightedChargeClaimValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WeightedChargeClaimEngine

        init(store: any WeightedChargeClaimStore, validator: WeightedChargeClaimValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WeightedChargeClaimEngine) {
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
                throw Kit.Failure("weighted charge claim \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedChargeClaimStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted charge claim \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedChargeClaimStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted charge claim \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newWeightedChargeClaimWorkflow(_ store: any WeightedChargeClaimStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> WeightedChargeClaimWorkflow {
        return WeightedChargeClaimWorkflow(
            store: store,
            validator: defaultWeightedChargeClaimValidator(),
            clock: clock,
            journal: [],
            engine: defaultWeightedChargeClaimEngine(flags)
        )
    }
}
