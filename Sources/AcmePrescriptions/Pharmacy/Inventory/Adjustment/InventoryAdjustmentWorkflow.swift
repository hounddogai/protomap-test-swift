import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves inventory adjustments through their life cycle and keeps a journal of what it did.
    final class InventoryAdjustmentManager {
        var store: any InventoryAdjustmentStore
        var validator: InventoryAdjustmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: InventoryAdjustmentEngine

        init(store: any InventoryAdjustmentStore, validator: InventoryAdjustmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: InventoryAdjustmentEngine) {
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
                throw Kit.Failure("inventory adjustment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(InventoryAdjustmentStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("inventory adjustment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(InventoryAdjustmentStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("inventory adjustment \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newInventoryAdjustmentManager(_ store: any InventoryAdjustmentStore, clock: any Kit.Clocks.Clock) -> InventoryAdjustmentManager {
        return InventoryAdjustmentManager(
            store: store,
            validator: defaultInventoryAdjustmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultInventoryAdjustmentEngine()
        )
    }
}
