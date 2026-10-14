import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves weighted risk score tiers through their life cycle and keeps a journal of what it did.
    final class WeightedRiskScoreTierWorkflow {
        var store: any WeightedRiskScoreTierStore
        var validator: WeightedRiskScoreTierValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any WeightedRiskScoreTierStore, validator: WeightedRiskScoreTierValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("weighted risk score tier \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedRiskScoreTierStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted risk score tier \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedRiskScoreTierStatus.expired)
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

    static func newWeightedRiskScoreTierWorkflow(_ store: any WeightedRiskScoreTierStore, clock: any Kit.Clocks.Clock) -> WeightedRiskScoreTierWorkflow {
        return WeightedRiskScoreTierWorkflow(
            store: store,
            validator: defaultWeightedRiskScoreTierValidator(),
            clock: clock,
            journal: []
        )
    }
}
