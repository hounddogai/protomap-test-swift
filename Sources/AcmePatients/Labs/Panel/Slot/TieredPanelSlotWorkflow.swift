import AcmePlatform
import Foundation

extension Labs {
    /// Moves tiered panel slots through their life cycle and keeps a journal of what it did.
    final class TieredPanelSlotManager {
        var store: any TieredPanelSlotStore
        var validator: TieredPanelSlotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TieredPanelSlotEngine

        init(store: any TieredPanelSlotStore, validator: TieredPanelSlotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TieredPanelSlotEngine) {
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
                throw Kit.Failure("tiered panel slot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredPanelSlotStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered panel slot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredPanelSlotStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered panel slot \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newTieredPanelSlotManager(_ store: any TieredPanelSlotStore, clock: any Kit.Clocks.Clock) -> TieredPanelSlotManager {
        return TieredPanelSlotManager(
            store: store,
            validator: defaultTieredPanelSlotValidator(),
            clock: clock,
            journal: [],
            engine: defaultTieredPanelSlotEngine()
        )
    }
}
