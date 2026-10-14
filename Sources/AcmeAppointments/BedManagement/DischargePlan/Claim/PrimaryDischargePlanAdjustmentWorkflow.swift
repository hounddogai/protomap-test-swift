import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves primary discharge plan adjustments through their life cycle and keeps a journal of what it did.
    final class PrimaryDischargePlanAdjustmentManager {
        var store: any PrimaryDischargePlanAdjustmentStore
        var validator: PrimaryDischargePlanAdjustmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrimaryDischargePlanAdjustmentEngine

        init(store: any PrimaryDischargePlanAdjustmentStore, validator: PrimaryDischargePlanAdjustmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrimaryDischargePlanAdjustmentEngine) {
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
                throw Kit.Failure("primary discharge plan adjustment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryDischargePlanAdjustmentStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary discharge plan adjustment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryDischargePlanAdjustmentStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary discharge plan adjustment \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newPrimaryDischargePlanAdjustmentManager(_ store: any PrimaryDischargePlanAdjustmentStore, clock: any Kit.Clocks.Clock) -> PrimaryDischargePlanAdjustmentManager {
        return PrimaryDischargePlanAdjustmentManager(
            store: store,
            validator: defaultPrimaryDischargePlanAdjustmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrimaryDischargePlanAdjustmentEngine()
        )
    }
}
