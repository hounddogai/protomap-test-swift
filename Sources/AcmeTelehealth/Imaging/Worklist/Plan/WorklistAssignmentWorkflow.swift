import AcmePlatform
import Foundation

extension Imaging {
    /// Moves worklist assignments through their life cycle and keeps a journal of what it did.
    final class WorklistAssignmentWorkflow {
        var store: any WorklistAssignmentStore
        var validator: WorklistAssignmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WorklistAssignmentEngine

        init(store: any WorklistAssignmentStore, validator: WorklistAssignmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WorklistAssignmentEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("worklist assignment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WorklistAssignmentStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("worklist assignment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WorklistAssignmentStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("worklist assignment \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newWorklistAssignmentWorkflow(_ store: any WorklistAssignmentStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> WorklistAssignmentWorkflow {
        return WorklistAssignmentWorkflow(
            store: store,
            validator: defaultWorklistAssignmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultWorklistAssignmentEngine(flags)
        )
    }
}
