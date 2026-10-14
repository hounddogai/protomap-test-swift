import AcmePlatform
import Foundation

extension Labs {
    /// Moves scheduled reference range rules through their life cycle and keeps a journal of what it did.
    final class ScheduledReferenceRangeRuleDesk {
        var store: any ScheduledReferenceRangeRuleStore
        var validator: ScheduledReferenceRangeRuleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ScheduledReferenceRangeRuleStore, validator: ScheduledReferenceRangeRuleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("scheduled reference range rule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledReferenceRangeRuleStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled reference range rule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledReferenceRangeRuleStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
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

    static func newScheduledReferenceRangeRuleDesk(_ store: any ScheduledReferenceRangeRuleStore, clock: any Kit.Clocks.Clock) -> ScheduledReferenceRangeRuleDesk {
        return ScheduledReferenceRangeRuleDesk(
            store: store,
            validator: defaultScheduledReferenceRangeRuleValidator(),
            clock: clock,
            journal: []
        )
    }
}
