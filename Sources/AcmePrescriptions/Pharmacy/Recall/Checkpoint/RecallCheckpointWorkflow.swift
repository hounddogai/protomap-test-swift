import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves recall checkpoints through their life cycle and keeps a journal of what it did.
    final class RecallCheckpointCoordinator {
        var store: any RecallCheckpointStore
        var validator: RecallCheckpointValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RecallCheckpointStore, validator: RecallCheckpointValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("recall checkpoint \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RecallCheckpointStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("recall checkpoint \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RecallCheckpointStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newRecallCheckpointCoordinator(_ store: any RecallCheckpointStore, clock: any Kit.Clocks.Clock) -> RecallCheckpointCoordinator {
        return RecallCheckpointCoordinator(
            store: store,
            validator: defaultRecallCheckpointValidator(),
            clock: clock,
            journal: []
        )
    }
}
