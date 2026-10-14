import AcmePlatform
import Foundation

extension Referrals {
    /// Moves follow up windows through their life cycle and keeps a journal of what it did.
    final class FollowUpWindowWorkflow {
        var store: any FollowUpWindowStore
        var validator: FollowUpWindowValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any FollowUpWindowStore, validator: FollowUpWindowValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("follow up window \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FollowUpWindowStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("follow up window \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FollowUpWindowStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
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

    static func newFollowUpWindowWorkflow(_ store: any FollowUpWindowStore, clock: any Kit.Clocks.Clock) -> FollowUpWindowWorkflow {
        return FollowUpWindowWorkflow(
            store: store,
            validator: defaultFollowUpWindowValidator(),
            clock: clock,
            journal: []
        )
    }
}
