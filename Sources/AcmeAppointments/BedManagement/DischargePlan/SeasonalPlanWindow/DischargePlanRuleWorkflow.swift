import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves discharge plan rules through their life cycle and keeps a journal of what it did.
    final class DischargePlanRuleDesk {
        var store: any DischargePlanRuleStore
        var validator: DischargePlanRuleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any DischargePlanRuleStore, validator: DischargePlanRuleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("discharge plan rule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DischargePlanRuleStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("discharge plan rule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DischargePlanRuleStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
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

    static func newDischargePlanRuleDesk(_ store: any DischargePlanRuleStore, clock: any Kit.Clocks.Clock) -> DischargePlanRuleDesk {
        return DischargePlanRuleDesk(
            store: store,
            validator: defaultDischargePlanRuleValidator(),
            clock: clock,
            journal: []
        )
    }
}
