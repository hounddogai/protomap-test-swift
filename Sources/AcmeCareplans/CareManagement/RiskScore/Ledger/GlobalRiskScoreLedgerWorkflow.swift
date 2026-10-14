import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves global risk score ledgers through their life cycle and keeps a journal of what it did.
    final class GlobalRiskScoreLedgerCoordinator {
        var store: any GlobalRiskScoreLedgerStore
        var validator: GlobalRiskScoreLedgerValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GlobalRiskScoreLedgerEngine

        init(store: any GlobalRiskScoreLedgerStore, validator: GlobalRiskScoreLedgerValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GlobalRiskScoreLedgerEngine) {
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
                throw Kit.Failure("global risk score ledger \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalRiskScoreLedgerStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global risk score ledger \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalRiskScoreLedgerStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("global risk score ledger \(code) not found")
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

    static func newGlobalRiskScoreLedgerCoordinator(_ store: any GlobalRiskScoreLedgerStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> GlobalRiskScoreLedgerCoordinator {
        return GlobalRiskScoreLedgerCoordinator(
            store: store,
            validator: defaultGlobalRiskScoreLedgerValidator(),
            clock: clock,
            journal: [],
            engine: defaultGlobalRiskScoreLedgerEngine(flags)
        )
    }
}
