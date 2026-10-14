import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves rolling recall proposals through their life cycle and keeps a journal of what it did.
    final class RollingRecallProposalManager {
        var store: any RollingRecallProposalStore
        var validator: RollingRecallProposalValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RollingRecallProposalStore, validator: RollingRecallProposalValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling recall proposal \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingRecallProposalStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling recall proposal \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingRecallProposalStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newRollingRecallProposalManager(_ store: any RollingRecallProposalStore, clock: any Kit.Clocks.Clock) -> RollingRecallProposalManager {
        return RollingRecallProposalManager(
            store: store,
            validator: defaultRollingRecallProposalValidator(),
            clock: clock,
            journal: []
        )
    }
}
