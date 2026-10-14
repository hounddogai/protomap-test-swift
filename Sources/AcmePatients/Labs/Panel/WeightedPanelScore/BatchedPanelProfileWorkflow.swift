import AcmePlatform
import Foundation

extension Labs {
    /// Moves batched panel profiles through their life cycle and keeps a journal of what it did.
    final class BatchedPanelProfileCoordinator {
        var store: any BatchedPanelProfileStore
        var validator: BatchedPanelProfileValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any BatchedPanelProfileStore, validator: BatchedPanelProfileValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("batched panel profile \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedPanelProfileStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched panel profile \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedPanelProfileStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newBatchedPanelProfileCoordinator(_ store: any BatchedPanelProfileStore, clock: any Kit.Clocks.Clock) -> BatchedPanelProfileCoordinator {
        return BatchedPanelProfileCoordinator(
            store: store,
            validator: defaultBatchedPanelProfileValidator(),
            clock: clock,
            journal: []
        )
    }
}
