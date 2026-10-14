import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves lenient goal proposals through their life cycle and keeps a journal of what it did.
    final class LenientGoalProposalWorkflow {
        var store: any LenientGoalProposalStore
        var validator: LenientGoalProposalValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any LenientGoalProposalStore, validator: LenientGoalProposalValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient goal proposal \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientGoalProposalStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient goal proposal \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientGoalProposalStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newLenientGoalProposalWorkflow(_ store: any LenientGoalProposalStore, clock: any Kit.Clocks.Clock) -> LenientGoalProposalWorkflow {
        return LenientGoalProposalWorkflow(
            store: store,
            validator: defaultLenientGoalProposalValidator(),
            clock: clock,
            journal: []
        )
    }
}
