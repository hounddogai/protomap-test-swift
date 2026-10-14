import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves weighted care gap adjustments through their life cycle and keeps a journal of what it did.
    final class WeightedCareGapAdjustmentService {
        var store: any WeightedCareGapAdjustmentStore
        var validator: WeightedCareGapAdjustmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WeightedCareGapAdjustmentEngine

        init(store: any WeightedCareGapAdjustmentStore, validator: WeightedCareGapAdjustmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WeightedCareGapAdjustmentEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted care gap adjustment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedCareGapAdjustmentStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted care gap adjustment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedCareGapAdjustmentStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted care gap adjustment \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newWeightedCareGapAdjustmentService(_ store: any WeightedCareGapAdjustmentStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> WeightedCareGapAdjustmentService {
        return WeightedCareGapAdjustmentService(
            store: store,
            validator: defaultWeightedCareGapAdjustmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultWeightedCareGapAdjustmentEngine(flags)
        )
    }
}
