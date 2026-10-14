import AcmePlatform
import Foundation

extension Imaging {
    /// Moves worklist targets through their life cycle and keeps a journal of what it did.
    final class WorklistTargetWorkflow {
        var store: any WorklistTargetStore
        var validator: WorklistTargetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any WorklistTargetStore, validator: WorklistTargetValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("worklist target \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WorklistTargetStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("worklist target \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WorklistTargetStatus.archived)
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

    static func newWorklistTargetWorkflow(_ store: any WorklistTargetStore, clock: any Kit.Clocks.Clock) -> WorklistTargetWorkflow {
        return WorklistTargetWorkflow(
            store: store,
            validator: defaultWorklistTargetValidator(),
            clock: clock,
            journal: []
        )
    }
}
