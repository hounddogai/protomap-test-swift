import AcmePlatform
import Foundation

extension Consent {
    /// Moves disclosure milestones through their life cycle and keeps a journal of what it did.
    final class DisclosureMilestoneDesk {
        var store: any DisclosureMilestoneStore
        var validator: DisclosureMilestoneValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any DisclosureMilestoneStore, validator: DisclosureMilestoneValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("disclosure milestone \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DisclosureMilestoneStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("disclosure milestone \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DisclosureMilestoneStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
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

    static func newDisclosureMilestoneDesk(_ store: any DisclosureMilestoneStore, clock: any Kit.Clocks.Clock) -> DisclosureMilestoneDesk {
        return DisclosureMilestoneDesk(
            store: store,
            validator: defaultDisclosureMilestoneValidator(),
            clock: clock,
            journal: []
        )
    }
}
