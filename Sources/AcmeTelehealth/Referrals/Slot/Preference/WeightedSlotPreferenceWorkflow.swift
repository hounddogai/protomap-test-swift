import AcmePlatform
import Foundation

extension Referrals {
    /// Moves weighted slot preferences through their life cycle and keeps a journal of what it did.
    final class WeightedSlotPreferenceDesk {
        var store: any WeightedSlotPreferenceStore
        var validator: WeightedSlotPreferenceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WeightedSlotPreferenceEngine

        init(store: any WeightedSlotPreferenceStore, validator: WeightedSlotPreferenceValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WeightedSlotPreferenceEngine) {
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
                throw Kit.Failure("weighted slot preference \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedSlotPreferenceStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted slot preference \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedSlotPreferenceStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted slot preference \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newWeightedSlotPreferenceDesk(_ store: any WeightedSlotPreferenceStore, clock: any Kit.Clocks.Clock) -> WeightedSlotPreferenceDesk {
        return WeightedSlotPreferenceDesk(
            store: store,
            validator: defaultWeightedSlotPreferenceValidator(),
            clock: clock,
            journal: [],
            engine: defaultWeightedSlotPreferenceEngine()
        )
    }
}
