import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves transfer records through their life cycle and keeps a journal of what it did.
    final class TransferRecordWorkflow {
        var store: any TransferRecordStore
        var validator: TransferRecordValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TransferRecordEngine

        init(store: any TransferRecordStore, validator: TransferRecordValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TransferRecordEngine) {
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
                throw Kit.Failure("transfer record \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TransferRecordStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("transfer record \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TransferRecordStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("transfer record \(code) not found")
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

    static func newTransferRecordWorkflow(_ store: any TransferRecordStore, clock: any Kit.Clocks.Clock) -> TransferRecordWorkflow {
        return TransferRecordWorkflow(
            store: store,
            validator: defaultTransferRecordValidator(),
            clock: clock,
            journal: [],
            engine: defaultTransferRecordEngine()
        )
    }
}
