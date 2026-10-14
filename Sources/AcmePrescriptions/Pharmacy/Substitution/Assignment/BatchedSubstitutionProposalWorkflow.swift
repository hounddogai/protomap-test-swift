import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves batched substitution proposals through their life cycle and keeps a journal of what it did.
    final class BatchedSubstitutionProposalManager {
        var store: any BatchedSubstitutionProposalStore
        var validator: BatchedSubstitutionProposalValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any BatchedSubstitutionProposalStore, validator: BatchedSubstitutionProposalValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("batched substitution proposal \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedSubstitutionProposalStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched substitution proposal \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedSubstitutionProposalStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
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

    static func newBatchedSubstitutionProposalManager(_ store: any BatchedSubstitutionProposalStore, clock: any Kit.Clocks.Clock) -> BatchedSubstitutionProposalManager {
        return BatchedSubstitutionProposalManager(
            store: store,
            validator: defaultBatchedSubstitutionProposalValidator(),
            clock: clock,
            journal: []
        )
    }
}
