import AcmePlatform
import Foundation

extension Referrals {
    /// Moves batched eligibility audits through their life cycle and keeps a journal of what it did.
    final class BatchedEligibilityAuditManager {
        var store: any BatchedEligibilityAuditStore
        var validator: BatchedEligibilityAuditValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BatchedEligibilityAuditEngine

        init(store: any BatchedEligibilityAuditStore, validator: BatchedEligibilityAuditValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BatchedEligibilityAuditEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched eligibility audit \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedEligibilityAuditStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched eligibility audit \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedEligibilityAuditStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched eligibility audit \(code) not found")
            }
            let result = engine.price(item)
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

    static func newBatchedEligibilityAuditManager(_ store: any BatchedEligibilityAuditStore, clock: any Kit.Clocks.Clock) -> BatchedEligibilityAuditManager {
        return BatchedEligibilityAuditManager(
            store: store,
            validator: defaultBatchedEligibilityAuditValidator(),
            clock: clock,
            journal: [],
            engine: defaultBatchedEligibilityAuditEngine()
        )
    }
}
