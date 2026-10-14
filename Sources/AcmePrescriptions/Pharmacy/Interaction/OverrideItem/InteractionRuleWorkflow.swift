import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves interaction rules through their life cycle and keeps a journal of what it did.
    final class InteractionRuleDesk {
        var store: any InteractionRuleStore
        var validator: InteractionRuleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any InteractionRuleStore, validator: InteractionRuleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("interaction rule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(InteractionRuleStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("interaction rule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(InteractionRuleStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newInteractionRuleDesk(_ store: any InteractionRuleStore, clock: any Kit.Clocks.Clock) -> InteractionRuleDesk {
        return InteractionRuleDesk(
            store: store,
            validator: defaultInteractionRuleValidator(),
            clock: clock,
            journal: []
        )
    }
}
