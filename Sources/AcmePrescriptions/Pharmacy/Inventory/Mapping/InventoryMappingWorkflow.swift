import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves inventory mappings through their life cycle and keeps a journal of what it did.
    final class InventoryMappingService {
        var store: any InventoryMappingStore
        var validator: InventoryMappingValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: InventoryMappingEngine

        init(store: any InventoryMappingStore, validator: InventoryMappingValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: InventoryMappingEngine) {
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
                throw Kit.Failure("inventory mapping \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(InventoryMappingStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("inventory mapping \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(InventoryMappingStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("inventory mapping \(code) not found")
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
                if item.startsAt > cutoff {
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

    static func newInventoryMappingService(_ store: any InventoryMappingStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> InventoryMappingService {
        return InventoryMappingService(
            store: store,
            validator: defaultInventoryMappingValidator(),
            clock: clock,
            journal: [],
            engine: defaultInventoryMappingEngine(flags)
        )
    }
}
