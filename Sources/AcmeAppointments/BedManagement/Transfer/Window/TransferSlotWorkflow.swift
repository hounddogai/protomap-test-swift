import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves transfer slots through their life cycle and keeps a journal of what it did.
    final class TransferSlotDesk {
        var store: any TransferSlotStore
        var validator: TransferSlotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TransferSlotEngine

        init(store: any TransferSlotStore, validator: TransferSlotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TransferSlotEngine) {
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
                throw Kit.Failure("transfer slot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TransferSlotStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("transfer slot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TransferSlotStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("transfer slot \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newTransferSlotDesk(_ store: any TransferSlotStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> TransferSlotDesk {
        return TransferSlotDesk(
            store: store,
            validator: defaultTransferSlotValidator(),
            clock: clock,
            journal: [],
            engine: defaultTransferSlotEngine(flags)
        )
    }
}
