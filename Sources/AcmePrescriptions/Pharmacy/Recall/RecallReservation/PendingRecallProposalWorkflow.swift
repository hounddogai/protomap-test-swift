import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves pending recall proposals through their life cycle and keeps a journal of what it did.
    final class PendingRecallProposalCoordinator {
        var store: any PendingRecallProposalStore
        var validator: PendingRecallProposalValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PendingRecallProposalStore, validator: PendingRecallProposalValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending recall proposal \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingRecallProposalStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending recall proposal \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingRecallProposalStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
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

    static func newPendingRecallProposalCoordinator(_ store: any PendingRecallProposalStore, clock: any Kit.Clocks.Clock) -> PendingRecallProposalCoordinator {
        return PendingRecallProposalCoordinator(
            store: store,
            validator: defaultPendingRecallProposalValidator(),
            clock: clock,
            journal: []
        )
    }
}
