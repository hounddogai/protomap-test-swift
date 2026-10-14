import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves batched outreach policies through their life cycle and keeps a journal of what it did.
    final class BatchedOutreachPolicyWorkflow {
        var store: any BatchedOutreachPolicyStore
        var validator: BatchedOutreachPolicyValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BatchedOutreachPolicyEngine

        init(store: any BatchedOutreachPolicyStore, validator: BatchedOutreachPolicyValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BatchedOutreachPolicyEngine) {
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
                throw Kit.Failure("batched outreach policy \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedOutreachPolicyStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched outreach policy \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedOutreachPolicyStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched outreach policy \(code) not found")
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

    static func newBatchedOutreachPolicyWorkflow(_ store: any BatchedOutreachPolicyStore, clock: any Kit.Clocks.Clock) -> BatchedOutreachPolicyWorkflow {
        return BatchedOutreachPolicyWorkflow(
            store: store,
            validator: defaultBatchedOutreachPolicyValidator(),
            clock: clock,
            journal: [],
            engine: defaultBatchedOutreachPolicyEngine()
        )
    }
}
