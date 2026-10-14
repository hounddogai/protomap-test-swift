import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves inventory thresholds through their life cycle and keeps a journal of what it did.
    final class InventoryThresholdDesk {
        var store: any InventoryThresholdStore
        var validator: InventoryThresholdValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: InventoryThresholdEngine

        init(store: any InventoryThresholdStore, validator: InventoryThresholdValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: InventoryThresholdEngine) {
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
                throw Kit.Failure("inventory threshold \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(InventoryThresholdStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("inventory threshold \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(InventoryThresholdStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("inventory threshold \(code) not found")
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

    static func newInventoryThresholdDesk(_ store: any InventoryThresholdStore, clock: any Kit.Clocks.Clock) -> InventoryThresholdDesk {
        return InventoryThresholdDesk(
            store: store,
            validator: defaultInventoryThresholdValidator(),
            clock: clock,
            journal: [],
            engine: defaultInventoryThresholdEngine()
        )
    }
}
