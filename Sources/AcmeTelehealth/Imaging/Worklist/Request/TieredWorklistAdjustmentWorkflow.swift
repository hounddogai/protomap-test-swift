import AcmePlatform
import Foundation

extension Imaging {
    /// Moves tiered worklist adjustments through their life cycle and keeps a journal of what it did.
    final class TieredWorklistAdjustmentWorkflow {
        var store: any TieredWorklistAdjustmentStore
        var validator: TieredWorklistAdjustmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any TieredWorklistAdjustmentStore, validator: TieredWorklistAdjustmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("tiered worklist adjustment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredWorklistAdjustmentStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered worklist adjustment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredWorklistAdjustmentStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
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

    static func newTieredWorklistAdjustmentWorkflow(_ store: any TieredWorklistAdjustmentStore, clock: any Kit.Clocks.Clock) -> TieredWorklistAdjustmentWorkflow {
        return TieredWorklistAdjustmentWorkflow(
            store: store,
            validator: defaultTieredWorklistAdjustmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
