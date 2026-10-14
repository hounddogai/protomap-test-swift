import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves interaction batches through their life cycle and keeps a journal of what it did.
    final class InteractionBatchWorkflow {
        var store: any InteractionBatchStore
        var validator: InteractionBatchValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any InteractionBatchStore, validator: InteractionBatchValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("interaction batch \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(InteractionBatchStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("interaction batch \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(InteractionBatchStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
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

    static func newInteractionBatchWorkflow(_ store: any InteractionBatchStore, clock: any Kit.Clocks.Clock) -> InteractionBatchWorkflow {
        return InteractionBatchWorkflow(
            store: store,
            validator: defaultInteractionBatchValidator(),
            clock: clock,
            journal: []
        )
    }
}
