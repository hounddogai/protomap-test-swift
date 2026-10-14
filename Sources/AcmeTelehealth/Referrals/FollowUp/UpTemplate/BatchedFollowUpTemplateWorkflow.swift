import AcmePlatform
import Foundation

extension Referrals {
    /// Moves batched follow up templates through their life cycle and keeps a journal of what it did.
    final class BatchedFollowUpTemplateDesk {
        var store: any BatchedFollowUpTemplateStore
        var validator: BatchedFollowUpTemplateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any BatchedFollowUpTemplateStore, validator: BatchedFollowUpTemplateValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("batched follow up template \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedFollowUpTemplateStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched follow up template \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedFollowUpTemplateStatus.stopped)
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

    static func newBatchedFollowUpTemplateDesk(_ store: any BatchedFollowUpTemplateStore, clock: any Kit.Clocks.Clock) -> BatchedFollowUpTemplateDesk {
        return BatchedFollowUpTemplateDesk(
            store: store,
            validator: defaultBatchedFollowUpTemplateValidator(),
            clock: clock,
            journal: []
        )
    }
}
