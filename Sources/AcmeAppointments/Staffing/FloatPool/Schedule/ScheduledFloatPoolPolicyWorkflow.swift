import AcmePlatform
import Foundation

extension Staffing {
    /// Moves scheduled float pool policies through their life cycle and keeps a journal of what it did.
    final class ScheduledFloatPoolPolicyCoordinator {
        var store: any ScheduledFloatPoolPolicyStore
        var validator: ScheduledFloatPoolPolicyValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ScheduledFloatPoolPolicyStore, validator: ScheduledFloatPoolPolicyValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("scheduled float pool policy \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledFloatPoolPolicyStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled float pool policy \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledFloatPoolPolicyStatus.expired)
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

    static func newScheduledFloatPoolPolicyCoordinator(_ store: any ScheduledFloatPoolPolicyStore, clock: any Kit.Clocks.Clock) -> ScheduledFloatPoolPolicyCoordinator {
        return ScheduledFloatPoolPolicyCoordinator(
            store: store,
            validator: defaultScheduledFloatPoolPolicyValidator(),
            clock: clock,
            journal: []
        )
    }
}
