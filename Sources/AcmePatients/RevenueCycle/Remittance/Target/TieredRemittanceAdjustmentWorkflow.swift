import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves tiered remittance adjustments through their life cycle and keeps a journal of what it did.
    final class TieredRemittanceAdjustmentService {
        var store: any TieredRemittanceAdjustmentStore
        var validator: TieredRemittanceAdjustmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TieredRemittanceAdjustmentEngine

        init(store: any TieredRemittanceAdjustmentStore, validator: TieredRemittanceAdjustmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TieredRemittanceAdjustmentEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered remittance adjustment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredRemittanceAdjustmentStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered remittance adjustment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredRemittanceAdjustmentStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered remittance adjustment \(code) not found")
            }
            let result = engine.price(item)
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

    static func newTieredRemittanceAdjustmentService(_ store: any TieredRemittanceAdjustmentStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> TieredRemittanceAdjustmentService {
        return TieredRemittanceAdjustmentService(
            store: store,
            validator: defaultTieredRemittanceAdjustmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultTieredRemittanceAdjustmentEngine(flags)
        )
    }
}
