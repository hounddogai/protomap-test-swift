import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves batched bed board slots through their life cycle and keeps a journal of what it did.
    final class BatchedBedBoardSlotCoordinator {
        var store: any BatchedBedBoardSlotStore
        var validator: BatchedBedBoardSlotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any BatchedBedBoardSlotStore, validator: BatchedBedBoardSlotValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("batched bed board slot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedBedBoardSlotStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched bed board slot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedBedBoardSlotStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
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

    static func newBatchedBedBoardSlotCoordinator(_ store: any BatchedBedBoardSlotStore, clock: any Kit.Clocks.Clock) -> BatchedBedBoardSlotCoordinator {
        return BatchedBedBoardSlotCoordinator(
            store: store,
            validator: defaultBatchedBedBoardSlotValidator(),
            clock: clock,
            journal: []
        )
    }
}
