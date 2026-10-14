import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves default outreach plans through their life cycle and keeps a journal of what it did.
    final class DefaultOutreachPlanManager {
        var store: any DefaultOutreachPlanStore
        var validator: DefaultOutreachPlanValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any DefaultOutreachPlanStore, validator: DefaultOutreachPlanValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("default outreach plan \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultOutreachPlanStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default outreach plan \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultOutreachPlanStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
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

    static func newDefaultOutreachPlanManager(_ store: any DefaultOutreachPlanStore, clock: any Kit.Clocks.Clock) -> DefaultOutreachPlanManager {
        return DefaultOutreachPlanManager(
            store: store,
            validator: defaultDefaultOutreachPlanValidator(),
            clock: clock,
            journal: []
        )
    }
}
