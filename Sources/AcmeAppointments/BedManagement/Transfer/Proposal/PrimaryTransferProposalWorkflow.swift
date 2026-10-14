import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves primary transfer proposals through their life cycle and keeps a journal of what it did.
    final class PrimaryTransferProposalManager {
        var store: any PrimaryTransferProposalStore
        var validator: PrimaryTransferProposalValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrimaryTransferProposalEngine

        init(store: any PrimaryTransferProposalStore, validator: PrimaryTransferProposalValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrimaryTransferProposalEngine) {
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
                throw Kit.Failure("primary transfer proposal \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryTransferProposalStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary transfer proposal \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryTransferProposalStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary transfer proposal \(code) not found")
            }
            let result = engine.price(item)
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

    static func newPrimaryTransferProposalManager(_ store: any PrimaryTransferProposalStore, clock: any Kit.Clocks.Clock) -> PrimaryTransferProposalManager {
        return PrimaryTransferProposalManager(
            store: store,
            validator: defaultPrimaryTransferProposalValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrimaryTransferProposalEngine()
        )
    }
}
