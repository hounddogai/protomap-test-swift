import AcmePlatform
import Foundation

extension Labs {
    /// Moves scheduled panel adjustments through their life cycle and keeps a journal of what it did.
    final class ScheduledPanelAdjustmentService {
        var store: any ScheduledPanelAdjustmentStore
        var validator: ScheduledPanelAdjustmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ScheduledPanelAdjustmentStore, validator: ScheduledPanelAdjustmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("scheduled panel adjustment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledPanelAdjustmentStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled panel adjustment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledPanelAdjustmentStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
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

    static func newScheduledPanelAdjustmentService(_ store: any ScheduledPanelAdjustmentStore, clock: any Kit.Clocks.Clock) -> ScheduledPanelAdjustmentService {
        return ScheduledPanelAdjustmentService(
            store: store,
            validator: defaultScheduledPanelAdjustmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
