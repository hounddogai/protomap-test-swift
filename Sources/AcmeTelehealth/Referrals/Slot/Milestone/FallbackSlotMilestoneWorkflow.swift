import AcmePlatform
import Foundation

extension Referrals {
    /// Moves fallback slot milestones through their life cycle and keeps a journal of what it did.
    final class FallbackSlotMilestoneWorkflow {
        var store: any FallbackSlotMilestoneStore
        var validator: FallbackSlotMilestoneValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any FallbackSlotMilestoneStore, validator: FallbackSlotMilestoneValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("fallback slot milestone \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackSlotMilestoneStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback slot milestone \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackSlotMilestoneStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newFallbackSlotMilestoneWorkflow(_ store: any FallbackSlotMilestoneStore, clock: any Kit.Clocks.Clock) -> FallbackSlotMilestoneWorkflow {
        return FallbackSlotMilestoneWorkflow(
            store: store,
            validator: defaultFallbackSlotMilestoneValidator(),
            clock: clock,
            journal: []
        )
    }
}
