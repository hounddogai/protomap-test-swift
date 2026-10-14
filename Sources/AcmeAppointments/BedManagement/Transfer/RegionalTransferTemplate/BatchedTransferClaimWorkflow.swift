import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves batched transfer claims through their life cycle and keeps a journal of what it did.
    final class BatchedTransferClaimDesk {
        var store: any BatchedTransferClaimStore
        var validator: BatchedTransferClaimValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any BatchedTransferClaimStore, validator: BatchedTransferClaimValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched transfer claim \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedTransferClaimStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched transfer claim \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedTransferClaimStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newBatchedTransferClaimDesk(_ store: any BatchedTransferClaimStore, clock: any Kit.Clocks.Clock) -> BatchedTransferClaimDesk {
        return BatchedTransferClaimDesk(
            store: store,
            validator: defaultBatchedTransferClaimValidator(),
            clock: clock,
            journal: []
        )
    }
}
