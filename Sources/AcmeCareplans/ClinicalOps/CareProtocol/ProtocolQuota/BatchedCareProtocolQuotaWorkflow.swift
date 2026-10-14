import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves batched care protocol quotas through their life cycle and keeps a journal of what it did.
    final class BatchedCareProtocolQuotaCoordinator {
        var store: any BatchedCareProtocolQuotaStore
        var validator: BatchedCareProtocolQuotaValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any BatchedCareProtocolQuotaStore, validator: BatchedCareProtocolQuotaValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched care protocol quota \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedCareProtocolQuotaStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched care protocol quota \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedCareProtocolQuotaStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
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

    static func newBatchedCareProtocolQuotaCoordinator(_ store: any BatchedCareProtocolQuotaStore, clock: any Kit.Clocks.Clock) -> BatchedCareProtocolQuotaCoordinator {
        return BatchedCareProtocolQuotaCoordinator(
            store: store,
            validator: defaultBatchedCareProtocolQuotaValidator(),
            clock: clock,
            journal: []
        )
    }
}
