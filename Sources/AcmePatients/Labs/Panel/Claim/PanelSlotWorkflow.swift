import AcmePlatform
import Foundation

extension Labs {
    /// Moves panel slots through their life cycle and keeps a journal of what it did.
    final class PanelSlotDesk {
        var store: any PanelSlotStore
        var validator: PanelSlotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PanelSlotEngine

        init(store: any PanelSlotStore, validator: PanelSlotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PanelSlotEngine) {
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
                throw Kit.Failure("panel slot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PanelSlotStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("panel slot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PanelSlotStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("panel slot \(code) not found")
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
                if item.expiresAt > cutoff {
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

    static func newPanelSlotDesk(_ store: any PanelSlotStore, clock: any Kit.Clocks.Clock) -> PanelSlotDesk {
        return PanelSlotDesk(
            store: store,
            validator: defaultPanelSlotValidator(),
            clock: clock,
            journal: [],
            engine: defaultPanelSlotEngine()
        )
    }
}
