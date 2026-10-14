import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves primary bed board ledgers through their life cycle and keeps a journal of what it did.
    final class PrimaryBedBoardLedgerCoordinator {
        var store: any PrimaryBedBoardLedgerStore
        var validator: PrimaryBedBoardLedgerValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrimaryBedBoardLedgerEngine

        init(store: any PrimaryBedBoardLedgerStore, validator: PrimaryBedBoardLedgerValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrimaryBedBoardLedgerEngine) {
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
                throw Kit.Failure("primary bed board ledger \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryBedBoardLedgerStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary bed board ledger \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryBedBoardLedgerStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary bed board ledger \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newPrimaryBedBoardLedgerCoordinator(_ store: any PrimaryBedBoardLedgerStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PrimaryBedBoardLedgerCoordinator {
        return PrimaryBedBoardLedgerCoordinator(
            store: store,
            validator: defaultPrimaryBedBoardLedgerValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrimaryBedBoardLedgerEngine(flags)
        )
    }
}
