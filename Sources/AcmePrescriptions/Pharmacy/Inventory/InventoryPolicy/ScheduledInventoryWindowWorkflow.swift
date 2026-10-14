import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves scheduled inventory windows through their life cycle and keeps a journal of what it did.
    final class ScheduledInventoryWindowService {
        var store: any ScheduledInventoryWindowStore
        var validator: ScheduledInventoryWindowValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ScheduledInventoryWindowEngine

        init(store: any ScheduledInventoryWindowStore, validator: ScheduledInventoryWindowValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ScheduledInventoryWindowEngine) {
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
                throw Kit.Failure("scheduled inventory window \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledInventoryWindowStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled inventory window \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledInventoryWindowStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled inventory window \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newScheduledInventoryWindowService(_ store: any ScheduledInventoryWindowStore, clock: any Kit.Clocks.Clock) -> ScheduledInventoryWindowService {
        return ScheduledInventoryWindowService(
            store: store,
            validator: defaultScheduledInventoryWindowValidator(),
            clock: clock,
            journal: [],
            engine: defaultScheduledInventoryWindowEngine()
        )
    }
}
