import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves adaptive assessment allocations through their life cycle and keeps a journal of what it did.
    final class AdaptiveAssessmentAllocationWorkflow {
        var store: any AdaptiveAssessmentAllocationStore
        var validator: AdaptiveAssessmentAllocationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any AdaptiveAssessmentAllocationStore, validator: AdaptiveAssessmentAllocationValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("adaptive assessment allocation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptiveAssessmentAllocationStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive assessment allocation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptiveAssessmentAllocationStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
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

    static func newAdaptiveAssessmentAllocationWorkflow(_ store: any AdaptiveAssessmentAllocationStore, clock: any Kit.Clocks.Clock) -> AdaptiveAssessmentAllocationWorkflow {
        return AdaptiveAssessmentAllocationWorkflow(
            store: store,
            validator: defaultAdaptiveAssessmentAllocationValidator(),
            clock: clock,
            journal: []
        )
    }
}
