import AcmePlatform
import Foundation

extension Labs {
    /// Moves weighted panel tiers through their life cycle and keeps a journal of what it did.
    final class WeightedPanelTierCoordinator {
        var store: any WeightedPanelTierStore
        var validator: WeightedPanelTierValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WeightedPanelTierEngine

        init(store: any WeightedPanelTierStore, validator: WeightedPanelTierValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WeightedPanelTierEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted panel tier \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedPanelTierStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted panel tier \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedPanelTierStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted panel tier \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newWeightedPanelTierCoordinator(_ store: any WeightedPanelTierStore, clock: any Kit.Clocks.Clock) -> WeightedPanelTierCoordinator {
        return WeightedPanelTierCoordinator(
            store: store,
            validator: defaultWeightedPanelTierValidator(),
            clock: clock,
            journal: [],
            engine: defaultWeightedPanelTierEngine()
        )
    }
}
