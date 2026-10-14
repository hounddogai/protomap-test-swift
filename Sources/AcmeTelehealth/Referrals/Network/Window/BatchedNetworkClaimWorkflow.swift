import AcmePlatform
import Foundation

extension Referrals {
    /// Moves batched network claims through their life cycle and keeps a journal of what it did.
    final class BatchedNetworkClaimManager {
        var store: any BatchedNetworkClaimStore
        var validator: BatchedNetworkClaimValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any BatchedNetworkClaimStore, validator: BatchedNetworkClaimValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched network claim \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedNetworkClaimStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched network claim \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedNetworkClaimStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
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

    static func newBatchedNetworkClaimManager(_ store: any BatchedNetworkClaimStore, clock: any Kit.Clocks.Clock) -> BatchedNetworkClaimManager {
        return BatchedNetworkClaimManager(
            store: store,
            validator: defaultBatchedNetworkClaimValidator(),
            clock: clock,
            journal: []
        )
    }
}
