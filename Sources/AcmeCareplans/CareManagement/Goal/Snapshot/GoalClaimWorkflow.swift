import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves goal claims through their life cycle and keeps a journal of what it did.
    final class GoalClaimManager {
        var store: any GoalClaimStore
        var validator: GoalClaimValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any GoalClaimStore, validator: GoalClaimValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("goal claim \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GoalClaimStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("goal claim \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GoalClaimStatus.archived)
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

    static func newGoalClaimManager(_ store: any GoalClaimStore, clock: any Kit.Clocks.Clock) -> GoalClaimManager {
        return GoalClaimManager(store: store, validator: defaultGoalClaimValidator(), clock: clock, journal: [])
    }
}
