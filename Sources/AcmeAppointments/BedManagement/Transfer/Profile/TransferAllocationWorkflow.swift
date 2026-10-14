import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves transfer allocations through their life cycle and keeps a journal of what it did.
    final class TransferAllocationService {
        var store: any TransferAllocationStore
        var validator: TransferAllocationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TransferAllocationEngine

        init(store: any TransferAllocationStore, validator: TransferAllocationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TransferAllocationEngine) {
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
                throw Kit.Failure("transfer allocation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TransferAllocationStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("transfer allocation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TransferAllocationStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("transfer allocation \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newTransferAllocationService(_ store: any TransferAllocationStore, clock: any Kit.Clocks.Clock) -> TransferAllocationService {
        return TransferAllocationService(
            store: store,
            validator: defaultTransferAllocationValidator(),
            clock: clock,
            journal: [],
            engine: defaultTransferAllocationEngine()
        )
    }
}
