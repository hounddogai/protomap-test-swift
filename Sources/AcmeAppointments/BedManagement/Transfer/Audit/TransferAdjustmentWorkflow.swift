import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves transfer adjustments through their life cycle and keeps a journal of what it did.
    final class TransferAdjustmentManager {
        var store: any TransferAdjustmentStore
        var validator: TransferAdjustmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any TransferAdjustmentStore, validator: TransferAdjustmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("transfer adjustment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TransferAdjustmentStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("transfer adjustment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TransferAdjustmentStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
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

    static func newTransferAdjustmentManager(_ store: any TransferAdjustmentStore, clock: any Kit.Clocks.Clock) -> TransferAdjustmentManager {
        return TransferAdjustmentManager(
            store: store,
            validator: defaultTransferAdjustmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
