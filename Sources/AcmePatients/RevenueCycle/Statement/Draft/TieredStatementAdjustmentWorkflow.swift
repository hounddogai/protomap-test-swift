import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves tiered statement adjustments through their life cycle and keeps a journal of what it did.
    final class TieredStatementAdjustmentCoordinator {
        var store: any TieredStatementAdjustmentStore
        var validator: TieredStatementAdjustmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TieredStatementAdjustmentEngine

        init(store: any TieredStatementAdjustmentStore, validator: TieredStatementAdjustmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TieredStatementAdjustmentEngine) {
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
                throw Kit.Failure("tiered statement adjustment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredStatementAdjustmentStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered statement adjustment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredStatementAdjustmentStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered statement adjustment \(code) not found")
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

    static func newTieredStatementAdjustmentCoordinator(_ store: any TieredStatementAdjustmentStore, clock: any Kit.Clocks.Clock) -> TieredStatementAdjustmentCoordinator {
        return TieredStatementAdjustmentCoordinator(
            store: store,
            validator: defaultTieredStatementAdjustmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultTieredStatementAdjustmentEngine()
        )
    }
}
