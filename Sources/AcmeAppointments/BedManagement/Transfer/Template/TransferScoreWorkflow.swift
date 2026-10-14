import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves transfer scores through their life cycle and keeps a journal of what it did.
    final class TransferScoreWorkflow {
        var store: any TransferScoreStore
        var validator: TransferScoreValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TransferScoreEngine

        init(store: any TransferScoreStore, validator: TransferScoreValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TransferScoreEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("transfer score \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TransferScoreStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("transfer score \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TransferScoreStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("transfer score \(code) not found")
            }
            let result = engine.run(item)
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

    static func newTransferScoreWorkflow(_ store: any TransferScoreStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> TransferScoreWorkflow {
        return TransferScoreWorkflow(
            store: store,
            validator: defaultTransferScoreValidator(),
            clock: clock,
            journal: [],
            engine: defaultTransferScoreEngine(flags)
        )
    }
}
