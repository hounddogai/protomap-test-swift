import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves denial adjustments through their life cycle and keeps a journal of what it did.
    final class DenialAdjustmentDesk {
        var store: any DenialAdjustmentStore
        var validator: DenialAdjustmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DenialAdjustmentEngine

        init(store: any DenialAdjustmentStore, validator: DenialAdjustmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DenialAdjustmentEngine) {
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
                throw Kit.Failure("denial adjustment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DenialAdjustmentStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("denial adjustment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DenialAdjustmentStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("denial adjustment \(code) not found")
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
                if item.updatedAt > cutoff {
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

    static func newDenialAdjustmentDesk(_ store: any DenialAdjustmentStore, clock: any Kit.Clocks.Clock) -> DenialAdjustmentDesk {
        return DenialAdjustmentDesk(
            store: store,
            validator: defaultDenialAdjustmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultDenialAdjustmentEngine()
        )
    }
}
