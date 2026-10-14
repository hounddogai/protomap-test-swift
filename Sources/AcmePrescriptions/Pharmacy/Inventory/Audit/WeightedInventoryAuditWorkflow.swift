import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves weighted inventory audits through their life cycle and keeps a journal of what it did.
    final class WeightedInventoryAuditDesk {
        var store: any WeightedInventoryAuditStore
        var validator: WeightedInventoryAuditValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WeightedInventoryAuditEngine

        init(store: any WeightedInventoryAuditStore, validator: WeightedInventoryAuditValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WeightedInventoryAuditEngine) {
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
                throw Kit.Failure("weighted inventory audit \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedInventoryAuditStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted inventory audit \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedInventoryAuditStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted inventory audit \(code) not found")
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

    static func newWeightedInventoryAuditDesk(_ store: any WeightedInventoryAuditStore, clock: any Kit.Clocks.Clock) -> WeightedInventoryAuditDesk {
        return WeightedInventoryAuditDesk(
            store: store,
            validator: defaultWeightedInventoryAuditValidator(),
            clock: clock,
            journal: [],
            engine: defaultWeightedInventoryAuditEngine()
        )
    }
}
