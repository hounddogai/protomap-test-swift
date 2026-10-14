import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves inventory tiers through their life cycle and keeps a journal of what it did.
    final class InventoryTierManager {
        var store: any InventoryTierStore
        var validator: InventoryTierValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: InventoryTierEngine

        init(store: any InventoryTierStore, validator: InventoryTierValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: InventoryTierEngine) {
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
                throw Kit.Failure("inventory tier \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(InventoryTierStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("inventory tier \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(InventoryTierStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("inventory tier \(code) not found")
            }
            let result = engine.price(item)
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

    static func newInventoryTierManager(_ store: any InventoryTierStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> InventoryTierManager {
        return InventoryTierManager(
            store: store,
            validator: defaultInventoryTierValidator(),
            clock: clock,
            journal: [],
            engine: defaultInventoryTierEngine(flags)
        )
    }
}
