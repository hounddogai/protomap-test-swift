import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves batched charge quotas through their life cycle and keeps a journal of what it did.
    final class BatchedChargeQuotaManager {
        var store: any BatchedChargeQuotaStore
        var validator: BatchedChargeQuotaValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BatchedChargeQuotaEngine

        init(store: any BatchedChargeQuotaStore, validator: BatchedChargeQuotaValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BatchedChargeQuotaEngine) {
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
                throw Kit.Failure("batched charge quota \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedChargeQuotaStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched charge quota \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedChargeQuotaStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched charge quota \(code) not found")
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

    static func newBatchedChargeQuotaManager(_ store: any BatchedChargeQuotaStore, clock: any Kit.Clocks.Clock) -> BatchedChargeQuotaManager {
        return BatchedChargeQuotaManager(
            store: store,
            validator: defaultBatchedChargeQuotaValidator(),
            clock: clock,
            journal: [],
            engine: defaultBatchedChargeQuotaEngine()
        )
    }
}
