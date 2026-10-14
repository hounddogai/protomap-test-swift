import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves batched claim assignments through their life cycle and keeps a journal of what it did.
    final class BatchedClaimAssignmentDesk {
        var store: any BatchedClaimAssignmentStore
        var validator: BatchedClaimAssignmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any BatchedClaimAssignmentStore, validator: BatchedClaimAssignmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched claim assignment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedClaimAssignmentStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched claim assignment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedClaimAssignmentStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
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

    static func newBatchedClaimAssignmentDesk(_ store: any BatchedClaimAssignmentStore, clock: any Kit.Clocks.Clock) -> BatchedClaimAssignmentDesk {
        return BatchedClaimAssignmentDesk(
            store: store,
            validator: defaultBatchedClaimAssignmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
