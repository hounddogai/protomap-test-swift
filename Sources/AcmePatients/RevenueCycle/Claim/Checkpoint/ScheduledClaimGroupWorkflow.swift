import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves scheduled claim groups through their life cycle and keeps a journal of what it did.
    final class ScheduledClaimGroupWorkflow {
        var store: any ScheduledClaimGroupStore
        var validator: ScheduledClaimGroupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ScheduledClaimGroupStore, validator: ScheduledClaimGroupValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("scheduled claim group \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledClaimGroupStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled claim group \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledClaimGroupStatus.stopped)
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

    static func newScheduledClaimGroupWorkflow(_ store: any ScheduledClaimGroupStore, clock: any Kit.Clocks.Clock) -> ScheduledClaimGroupWorkflow {
        return ScheduledClaimGroupWorkflow(
            store: store,
            validator: defaultScheduledClaimGroupValidator(),
            clock: clock,
            journal: []
        )
    }
}
