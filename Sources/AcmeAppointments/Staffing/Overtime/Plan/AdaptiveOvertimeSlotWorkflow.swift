import AcmePlatform
import Foundation

extension Staffing {
    /// Moves adaptive overtime slots through their life cycle and keeps a journal of what it did.
    final class AdaptiveOvertimeSlotWorkflow {
        var store: any AdaptiveOvertimeSlotStore
        var validator: AdaptiveOvertimeSlotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any AdaptiveOvertimeSlotStore, validator: AdaptiveOvertimeSlotValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("adaptive overtime slot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptiveOvertimeSlotStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive overtime slot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptiveOvertimeSlotStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newAdaptiveOvertimeSlotWorkflow(_ store: any AdaptiveOvertimeSlotStore, clock: any Kit.Clocks.Clock) -> AdaptiveOvertimeSlotWorkflow {
        return AdaptiveOvertimeSlotWorkflow(
            store: store,
            validator: defaultAdaptiveOvertimeSlotValidator(),
            clock: clock,
            journal: []
        )
    }
}
