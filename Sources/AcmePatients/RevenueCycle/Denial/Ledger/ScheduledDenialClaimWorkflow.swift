import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves scheduled denial claims through their life cycle and keeps a journal of what it did.
    final class ScheduledDenialClaimDesk {
        var store: any ScheduledDenialClaimStore
        var validator: ScheduledDenialClaimValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ScheduledDenialClaimStore, validator: ScheduledDenialClaimValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("scheduled denial claim \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledDenialClaimStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled denial claim \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledDenialClaimStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
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

    static func newScheduledDenialClaimDesk(_ store: any ScheduledDenialClaimStore, clock: any Kit.Clocks.Clock) -> ScheduledDenialClaimDesk {
        return ScheduledDenialClaimDesk(
            store: store,
            validator: defaultScheduledDenialClaimValidator(),
            clock: clock,
            journal: []
        )
    }
}
