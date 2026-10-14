import AcmePlatform
import Foundation

extension Referrals {
    /// Moves follow up proposals through their life cycle and keeps a journal of what it did.
    final class FollowUpProposalCoordinator {
        var store: any FollowUpProposalStore
        var validator: FollowUpProposalValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FollowUpProposalEngine

        init(store: any FollowUpProposalStore, validator: FollowUpProposalValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FollowUpProposalEngine) {
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
                throw Kit.Failure("follow up proposal \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FollowUpProposalStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("follow up proposal \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FollowUpProposalStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("follow up proposal \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newFollowUpProposalCoordinator(_ store: any FollowUpProposalStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> FollowUpProposalCoordinator {
        return FollowUpProposalCoordinator(
            store: store,
            validator: defaultFollowUpProposalValidator(),
            clock: clock,
            journal: [],
            engine: defaultFollowUpProposalEngine(flags)
        )
    }
}
