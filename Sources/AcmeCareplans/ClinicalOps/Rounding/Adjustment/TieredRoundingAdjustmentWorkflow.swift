import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves tiered rounding adjustments through their life cycle and keeps a journal of what it did.
    final class TieredRoundingAdjustmentDesk {
        var store: any TieredRoundingAdjustmentStore
        var validator: TieredRoundingAdjustmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TieredRoundingAdjustmentEngine

        init(store: any TieredRoundingAdjustmentStore, validator: TieredRoundingAdjustmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TieredRoundingAdjustmentEngine) {
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
                throw Kit.Failure("tiered rounding adjustment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredRoundingAdjustmentStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered rounding adjustment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredRoundingAdjustmentStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered rounding adjustment \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newTieredRoundingAdjustmentDesk(_ store: any TieredRoundingAdjustmentStore, clock: any Kit.Clocks.Clock) -> TieredRoundingAdjustmentDesk {
        return TieredRoundingAdjustmentDesk(
            store: store,
            validator: defaultTieredRoundingAdjustmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultTieredRoundingAdjustmentEngine()
        )
    }
}
