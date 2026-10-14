import AcmePlatform
import Foundation

extension Consent {
    /// Moves batched proxy claims through their life cycle and keeps a journal of what it did.
    final class BatchedProxyClaimService {
        var store: any BatchedProxyClaimStore
        var validator: BatchedProxyClaimValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any BatchedProxyClaimStore, validator: BatchedProxyClaimValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched proxy claim \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedProxyClaimStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched proxy claim \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedProxyClaimStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newBatchedProxyClaimService(_ store: any BatchedProxyClaimStore, clock: any Kit.Clocks.Clock) -> BatchedProxyClaimService {
        return BatchedProxyClaimService(
            store: store,
            validator: defaultBatchedProxyClaimValidator(),
            clock: clock,
            journal: []
        )
    }
}
