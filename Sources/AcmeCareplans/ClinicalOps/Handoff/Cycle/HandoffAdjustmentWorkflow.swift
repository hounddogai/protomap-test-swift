import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves handoff adjustments through their life cycle and keeps a journal of what it did.
    final class HandoffAdjustmentWorkflow {
        var store: any HandoffAdjustmentStore
        var validator: HandoffAdjustmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any HandoffAdjustmentStore, validator: HandoffAdjustmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("handoff adjustment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(HandoffAdjustmentStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("handoff adjustment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(HandoffAdjustmentStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
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

    static func newHandoffAdjustmentWorkflow(_ store: any HandoffAdjustmentStore, clock: any Kit.Clocks.Clock) -> HandoffAdjustmentWorkflow {
        return HandoffAdjustmentWorkflow(
            store: store,
            validator: defaultHandoffAdjustmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
