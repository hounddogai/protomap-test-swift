import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves task proposals through their life cycle and keeps a journal of what it did.
    final class TaskProposalService {
        var store: any TaskProposalStore
        var validator: TaskProposalValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TaskProposalEngine

        init(store: any TaskProposalStore, validator: TaskProposalValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TaskProposalEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("task proposal \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TaskProposalStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("task proposal \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TaskProposalStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("task proposal \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newTaskProposalService(_ store: any TaskProposalStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> TaskProposalService {
        return TaskProposalService(
            store: store,
            validator: defaultTaskProposalValidator(),
            clock: clock,
            journal: [],
            engine: defaultTaskProposalEngine(flags)
        )
    }
}
