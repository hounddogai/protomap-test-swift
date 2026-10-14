import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves inventory records through their life cycle and keeps a journal of what it did.
    final class InventoryRecordService {
        var store: any InventoryRecordStore
        var validator: InventoryRecordValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: InventoryRecordEngine

        init(store: any InventoryRecordStore, validator: InventoryRecordValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: InventoryRecordEngine) {
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
                throw Kit.Failure("inventory record \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(InventoryRecordStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("inventory record \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(InventoryRecordStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("inventory record \(code) not found")
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

    static func newInventoryRecordService(_ store: any InventoryRecordStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> InventoryRecordService {
        return InventoryRecordService(
            store: store,
            validator: defaultInventoryRecordValidator(),
            clock: clock,
            journal: [],
            engine: defaultInventoryRecordEngine(flags)
        )
    }
}
