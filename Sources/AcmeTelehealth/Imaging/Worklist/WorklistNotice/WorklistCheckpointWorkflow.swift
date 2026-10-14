import AcmePlatform
import Foundation

extension Imaging {
    /// Moves worklist checkpoints through their life cycle and keeps a journal of what it did.
    final class WorklistCheckpointCoordinator {
        var store: any WorklistCheckpointStore
        var validator: WorklistCheckpointValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WorklistCheckpointEngine

        init(store: any WorklistCheckpointStore, validator: WorklistCheckpointValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WorklistCheckpointEngine) {
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
                throw Kit.Failure("worklist checkpoint \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WorklistCheckpointStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("worklist checkpoint \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WorklistCheckpointStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("worklist checkpoint \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newWorklistCheckpointCoordinator(_ store: any WorklistCheckpointStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> WorklistCheckpointCoordinator {
        return WorklistCheckpointCoordinator(
            store: store,
            validator: defaultWorklistCheckpointValidator(),
            clock: clock,
            journal: [],
            engine: defaultWorklistCheckpointEngine(flags)
        )
    }
}
