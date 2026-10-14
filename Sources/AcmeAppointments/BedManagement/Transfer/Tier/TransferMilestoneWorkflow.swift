import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves transfer milestones through their life cycle and keeps a journal of what it did.
    final class TransferMilestoneService {
        var store: any TransferMilestoneStore
        var validator: TransferMilestoneValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any TransferMilestoneStore, validator: TransferMilestoneValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("transfer milestone \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TransferMilestoneStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("transfer milestone \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TransferMilestoneStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
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

    static func newTransferMilestoneService(_ store: any TransferMilestoneStore, clock: any Kit.Clocks.Clock) -> TransferMilestoneService {
        return TransferMilestoneService(
            store: store,
            validator: defaultTransferMilestoneValidator(),
            clock: clock,
            journal: []
        )
    }
}
