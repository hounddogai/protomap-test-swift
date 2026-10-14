import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves rolling transfer proposals through their life cycle and keeps a journal of what it did.
    final class RollingTransferProposalWorkflow {
        var store: any RollingTransferProposalStore
        var validator: RollingTransferProposalValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RollingTransferProposalEngine

        init(store: any RollingTransferProposalStore, validator: RollingTransferProposalValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RollingTransferProposalEngine) {
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
                throw Kit.Failure("rolling transfer proposal \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingTransferProposalStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling transfer proposal \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingTransferProposalStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling transfer proposal \(code) not found")
            }
            let result = engine.price(item)
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

    static func newRollingTransferProposalWorkflow(_ store: any RollingTransferProposalStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RollingTransferProposalWorkflow {
        return RollingTransferProposalWorkflow(
            store: store,
            validator: defaultRollingTransferProposalValidator(),
            clock: clock,
            journal: [],
            engine: defaultRollingTransferProposalEngine(flags)
        )
    }
}
