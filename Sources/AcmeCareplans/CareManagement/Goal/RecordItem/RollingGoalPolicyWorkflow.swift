import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves rolling goal policies through their life cycle and keeps a journal of what it did.
    final class RollingGoalPolicyDesk {
        var store: any RollingGoalPolicyStore
        var validator: RollingGoalPolicyValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RollingGoalPolicyStore, validator: RollingGoalPolicyValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("rolling goal policy \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingGoalPolicyStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling goal policy \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingGoalPolicyStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newRollingGoalPolicyDesk(_ store: any RollingGoalPolicyStore, clock: any Kit.Clocks.Clock) -> RollingGoalPolicyDesk {
        return RollingGoalPolicyDesk(
            store: store,
            validator: defaultRollingGoalPolicyValidator(),
            clock: clock,
            journal: []
        )
    }
}
