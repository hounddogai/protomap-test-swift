import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves transfer tiers through their life cycle and keeps a journal of what it did.
    final class TransferTierWorkflow {
        var store: any TransferTierStore
        var validator: TransferTierValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TransferTierEngine

        init(store: any TransferTierStore, validator: TransferTierValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TransferTierEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("transfer tier \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TransferTierStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("transfer tier \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TransferTierStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("transfer tier \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newTransferTierWorkflow(_ store: any TransferTierStore, clock: any Kit.Clocks.Clock) -> TransferTierWorkflow {
        return TransferTierWorkflow(
            store: store,
            validator: defaultTransferTierValidator(),
            clock: clock,
            journal: [],
            engine: defaultTransferTierEngine()
        )
    }
}
