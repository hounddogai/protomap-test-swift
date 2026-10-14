import AcmePlatform
import Foundation

extension Imaging {
    /// Moves pending read proposals through their life cycle and keeps a journal of what it did.
    final class PendingReadProposalCoordinator {
        var store: any PendingReadProposalStore
        var validator: PendingReadProposalValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PendingReadProposalStore, validator: PendingReadProposalValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("pending read proposal \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingReadProposalStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending read proposal \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingReadProposalStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newPendingReadProposalCoordinator(_ store: any PendingReadProposalStore, clock: any Kit.Clocks.Clock) -> PendingReadProposalCoordinator {
        return PendingReadProposalCoordinator(
            store: store,
            validator: defaultPendingReadProposalValidator(),
            clock: clock,
            journal: []
        )
    }
}
