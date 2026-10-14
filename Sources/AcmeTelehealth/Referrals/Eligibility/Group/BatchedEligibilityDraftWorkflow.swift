import AcmePlatform
import Foundation

extension Referrals {
    /// Moves batched eligibility drafts through their life cycle and keeps a journal of what it did.
    final class BatchedEligibilityDraftDesk {
        var store: any BatchedEligibilityDraftStore
        var validator: BatchedEligibilityDraftValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BatchedEligibilityDraftEngine

        init(store: any BatchedEligibilityDraftStore, validator: BatchedEligibilityDraftValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BatchedEligibilityDraftEngine) {
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
                throw Kit.Failure("batched eligibility draft \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedEligibilityDraftStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched eligibility draft \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedEligibilityDraftStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched eligibility draft \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newBatchedEligibilityDraftDesk(_ store: any BatchedEligibilityDraftStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> BatchedEligibilityDraftDesk {
        return BatchedEligibilityDraftDesk(
            store: store,
            validator: defaultBatchedEligibilityDraftValidator(),
            clock: clock,
            journal: [],
            engine: defaultBatchedEligibilityDraftEngine(flags)
        )
    }
}
