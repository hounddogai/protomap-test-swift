import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves global denial milestones through their life cycle and keeps a journal of what it did.
    final class GlobalDenialMilestoneManager {
        var store: any GlobalDenialMilestoneStore
        var validator: GlobalDenialMilestoneValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any GlobalDenialMilestoneStore, validator: GlobalDenialMilestoneValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("global denial milestone \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalDenialMilestoneStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global denial milestone \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalDenialMilestoneStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newGlobalDenialMilestoneManager(_ store: any GlobalDenialMilestoneStore, clock: any Kit.Clocks.Clock) -> GlobalDenialMilestoneManager {
        return GlobalDenialMilestoneManager(
            store: store,
            validator: defaultGlobalDenialMilestoneValidator(),
            clock: clock,
            journal: []
        )
    }
}
