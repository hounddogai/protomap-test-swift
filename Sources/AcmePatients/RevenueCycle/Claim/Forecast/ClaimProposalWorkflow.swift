import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves claim proposals through their life cycle and keeps a journal of what it did.
    final class ClaimProposalService {
        var store: any ClaimProposalStore
        var validator: ClaimProposalValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ClaimProposalEngine

        init(store: any ClaimProposalStore, validator: ClaimProposalValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ClaimProposalEngine) {
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
                throw Kit.Failure("claim proposal \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ClaimProposalStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("claim proposal \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ClaimProposalStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("claim proposal \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newClaimProposalService(_ store: any ClaimProposalStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ClaimProposalService {
        return ClaimProposalService(
            store: store,
            validator: defaultClaimProposalValidator(),
            clock: clock,
            journal: [],
            engine: defaultClaimProposalEngine(flags)
        )
    }
}
