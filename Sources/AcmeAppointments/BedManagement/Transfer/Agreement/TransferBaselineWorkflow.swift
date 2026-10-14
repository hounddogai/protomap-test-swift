import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves transfer baselines through their life cycle and keeps a journal of what it did.
    final class TransferBaselineWorkflow {
        var store: any TransferBaselineStore
        var validator: TransferBaselineValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any TransferBaselineStore, validator: TransferBaselineValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("transfer baseline \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TransferBaselineStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("transfer baseline \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TransferBaselineStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
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

    static func newTransferBaselineWorkflow(_ store: any TransferBaselineStore, clock: any Kit.Clocks.Clock) -> TransferBaselineWorkflow {
        return TransferBaselineWorkflow(
            store: store,
            validator: defaultTransferBaselineValidator(),
            clock: clock,
            journal: []
        )
    }
}
