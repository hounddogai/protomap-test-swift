import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves inventory proposals through their life cycle and keeps a journal of what it did.
    final class InventoryProposalManager {
        var store: any InventoryProposalStore
        var validator: InventoryProposalValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: InventoryProposalEngine

        init(store: any InventoryProposalStore, validator: InventoryProposalValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: InventoryProposalEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("inventory proposal \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(InventoryProposalStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("inventory proposal \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(InventoryProposalStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("inventory proposal \(code) not found")
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

    static func newInventoryProposalManager(_ store: any InventoryProposalStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> InventoryProposalManager {
        return InventoryProposalManager(
            store: store,
            validator: defaultInventoryProposalValidator(),
            clock: clock,
            journal: [],
            engine: defaultInventoryProposalEngine(flags)
        )
    }
}
