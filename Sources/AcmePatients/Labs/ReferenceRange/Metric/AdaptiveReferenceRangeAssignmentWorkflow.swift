import AcmePlatform
import Foundation

extension Labs {
    /// Moves adaptive reference range assignments through their life cycle and keeps a journal of what it did.
    final class AdaptiveReferenceRangeAssignmentWorkflow {
        var store: any AdaptiveReferenceRangeAssignmentStore
        var validator: AdaptiveReferenceRangeAssignmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any AdaptiveReferenceRangeAssignmentStore, validator: AdaptiveReferenceRangeAssignmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("adaptive reference range assignment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptiveReferenceRangeAssignmentStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive reference range assignment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptiveReferenceRangeAssignmentStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
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

    static func newAdaptiveReferenceRangeAssignmentWorkflow(_ store: any AdaptiveReferenceRangeAssignmentStore, clock: any Kit.Clocks.Clock) -> AdaptiveReferenceRangeAssignmentWorkflow {
        return AdaptiveReferenceRangeAssignmentWorkflow(
            store: store,
            validator: defaultAdaptiveReferenceRangeAssignmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
