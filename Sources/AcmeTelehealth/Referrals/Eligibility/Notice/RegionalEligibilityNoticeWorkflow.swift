import AcmePlatform
import Foundation

extension Referrals {
    /// Moves regional eligibility notices through their life cycle and keeps a journal of what it did.
    final class RegionalEligibilityNoticeWorkflow {
        var store: any RegionalEligibilityNoticeStore
        var validator: RegionalEligibilityNoticeValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RegionalEligibilityNoticeStore, validator: RegionalEligibilityNoticeValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("regional eligibility notice \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalEligibilityNoticeStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional eligibility notice \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalEligibilityNoticeStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
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

    static func newRegionalEligibilityNoticeWorkflow(_ store: any RegionalEligibilityNoticeStore, clock: any Kit.Clocks.Clock) -> RegionalEligibilityNoticeWorkflow {
        return RegionalEligibilityNoticeWorkflow(
            store: store,
            validator: defaultRegionalEligibilityNoticeValidator(),
            clock: clock,
            journal: []
        )
    }
}
