import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves scheduled inventory slots through their life cycle and keeps a journal of what it did.
    final class ScheduledInventorySlotManager {
        var store: any ScheduledInventorySlotStore
        var validator: ScheduledInventorySlotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ScheduledInventorySlotEngine

        init(store: any ScheduledInventorySlotStore, validator: ScheduledInventorySlotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ScheduledInventorySlotEngine) {
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
                throw Kit.Failure("scheduled inventory slot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledInventorySlotStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled inventory slot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledInventorySlotStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled inventory slot \(code) not found")
            }
            let result = engine.run(item)
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

    static func newScheduledInventorySlotManager(_ store: any ScheduledInventorySlotStore, clock: any Kit.Clocks.Clock) -> ScheduledInventorySlotManager {
        return ScheduledInventorySlotManager(
            store: store,
            validator: defaultScheduledInventorySlotValidator(),
            clock: clock,
            journal: [],
            engine: defaultScheduledInventorySlotEngine()
        )
    }
}
