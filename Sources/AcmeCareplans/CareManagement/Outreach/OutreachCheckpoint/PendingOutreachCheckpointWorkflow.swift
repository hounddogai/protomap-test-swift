import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves pending outreach checkpoints through their life cycle and keeps a journal of what it did.
    final class PendingOutreachCheckpointWorkflow {
        var store: any PendingOutreachCheckpointStore
        var validator: PendingOutreachCheckpointValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PendingOutreachCheckpointEngine

        init(store: any PendingOutreachCheckpointStore, validator: PendingOutreachCheckpointValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PendingOutreachCheckpointEngine) {
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
                throw Kit.Failure("pending outreach checkpoint \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingOutreachCheckpointStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending outreach checkpoint \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingOutreachCheckpointStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending outreach checkpoint \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newPendingOutreachCheckpointWorkflow(_ store: any PendingOutreachCheckpointStore, clock: any Kit.Clocks.Clock) -> PendingOutreachCheckpointWorkflow {
        return PendingOutreachCheckpointWorkflow(
            store: store,
            validator: defaultPendingOutreachCheckpointValidator(),
            clock: clock,
            journal: [],
            engine: defaultPendingOutreachCheckpointEngine()
        )
    }
}
