import AcmePlatform
import Foundation

extension Referrals {
    /// Moves scheduled network rules through their life cycle and keeps a journal of what it did.
    final class ScheduledNetworkRuleManager {
        var store: any ScheduledNetworkRuleStore
        var validator: ScheduledNetworkRuleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ScheduledNetworkRuleStore, validator: ScheduledNetworkRuleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled network rule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledNetworkRuleStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled network rule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledNetworkRuleStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newScheduledNetworkRuleManager(_ store: any ScheduledNetworkRuleStore, clock: any Kit.Clocks.Clock) -> ScheduledNetworkRuleManager {
        return ScheduledNetworkRuleManager(
            store: store,
            validator: defaultScheduledNetworkRuleValidator(),
            clock: clock,
            journal: []
        )
    }
}
