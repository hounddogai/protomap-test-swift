import AcmePlatform
import Foundation

extension Referrals {
    /// Moves slot adjustments through their life cycle and keeps a journal of what it did.
    final class SlotAdjustmentDesk {
        var store: any SlotAdjustmentStore
        var validator: SlotAdjustmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SlotAdjustmentEngine

        init(store: any SlotAdjustmentStore, validator: SlotAdjustmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SlotAdjustmentEngine) {
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
                throw Kit.Failure("slot adjustment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SlotAdjustmentStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("slot adjustment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SlotAdjustmentStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("slot adjustment \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newSlotAdjustmentDesk(_ store: any SlotAdjustmentStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> SlotAdjustmentDesk {
        return SlotAdjustmentDesk(
            store: store,
            validator: defaultSlotAdjustmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultSlotAdjustmentEngine(flags)
        )
    }
}
