import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves batched bed board allocations through their life cycle and keeps a journal of what it did.
    final class BatchedBedBoardAllocationService {
        var store: any BatchedBedBoardAllocationStore
        var validator: BatchedBedBoardAllocationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any BatchedBedBoardAllocationStore, validator: BatchedBedBoardAllocationValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("batched bed board allocation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedBedBoardAllocationStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched bed board allocation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedBedBoardAllocationStatus.failed)
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

    static func newBatchedBedBoardAllocationService(_ store: any BatchedBedBoardAllocationStore, clock: any Kit.Clocks.Clock) -> BatchedBedBoardAllocationService {
        return BatchedBedBoardAllocationService(
            store: store,
            validator: defaultBatchedBedBoardAllocationValidator(),
            clock: clock,
            journal: []
        )
    }
}
