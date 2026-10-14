import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves weighted transfer slots through their life cycle and keeps a journal of what it did.
    final class WeightedTransferSlotDesk {
        var store: any WeightedTransferSlotStore
        var validator: WeightedTransferSlotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WeightedTransferSlotEngine

        init(store: any WeightedTransferSlotStore, validator: WeightedTransferSlotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WeightedTransferSlotEngine) {
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
                throw Kit.Failure("weighted transfer slot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedTransferSlotStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted transfer slot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedTransferSlotStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted transfer slot \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newWeightedTransferSlotDesk(_ store: any WeightedTransferSlotStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> WeightedTransferSlotDesk {
        return WeightedTransferSlotDesk(
            store: store,
            validator: defaultWeightedTransferSlotValidator(),
            clock: clock,
            journal: [],
            engine: defaultWeightedTransferSlotEngine(flags)
        )
    }
}
