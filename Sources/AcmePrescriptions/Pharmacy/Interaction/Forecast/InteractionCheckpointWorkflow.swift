import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves interaction checkpoints through their life cycle and keeps a journal of what it did.
    final class InteractionCheckpointService {
        var store: any InteractionCheckpointStore
        var validator: InteractionCheckpointValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any InteractionCheckpointStore, validator: InteractionCheckpointValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("interaction checkpoint \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(InteractionCheckpointStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("interaction checkpoint \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(InteractionCheckpointStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
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

    static func newInteractionCheckpointService(_ store: any InteractionCheckpointStore, clock: any Kit.Clocks.Clock) -> InteractionCheckpointService {
        return InteractionCheckpointService(
            store: store,
            validator: defaultInteractionCheckpointValidator(),
            clock: clock,
            journal: []
        )
    }
}
