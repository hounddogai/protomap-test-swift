import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves pending charge proposals through their life cycle and keeps a journal of what it did.
    final class PendingChargeProposalWorkflow {
        var store: any PendingChargeProposalStore
        var validator: PendingChargeProposalValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PendingChargeProposalEngine

        init(store: any PendingChargeProposalStore, validator: PendingChargeProposalValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PendingChargeProposalEngine) {
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
                throw Kit.Failure("pending charge proposal \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingChargeProposalStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending charge proposal \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingChargeProposalStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending charge proposal \(code) not found")
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

    static func newPendingChargeProposalWorkflow(_ store: any PendingChargeProposalStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PendingChargeProposalWorkflow {
        return PendingChargeProposalWorkflow(
            store: store,
            validator: defaultPendingChargeProposalValidator(),
            clock: clock,
            journal: [],
            engine: defaultPendingChargeProposalEngine(flags)
        )
    }
}
