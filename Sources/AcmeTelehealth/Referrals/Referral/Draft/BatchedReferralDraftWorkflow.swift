import AcmePlatform
import Foundation

extension Referrals {
    /// Moves batched referral drafts through their life cycle and keeps a journal of what it did.
    final class BatchedReferralDraftManager {
        var store: any BatchedReferralDraftStore
        var validator: BatchedReferralDraftValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BatchedReferralDraftEngine

        init(store: any BatchedReferralDraftStore, validator: BatchedReferralDraftValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BatchedReferralDraftEngine) {
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
                throw Kit.Failure("batched referral draft \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedReferralDraftStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched referral draft \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedReferralDraftStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched referral draft \(code) not found")
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

    static func newBatchedReferralDraftManager(_ store: any BatchedReferralDraftStore, clock: any Kit.Clocks.Clock) -> BatchedReferralDraftManager {
        return BatchedReferralDraftManager(
            store: store,
            validator: defaultBatchedReferralDraftValidator(),
            clock: clock,
            journal: [],
            engine: defaultBatchedReferralDraftEngine()
        )
    }
}
