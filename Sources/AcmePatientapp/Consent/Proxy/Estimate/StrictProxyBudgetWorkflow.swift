import AcmePlatform
import Foundation

extension Consent {
    /// Moves strict proxy budgets through their life cycle and keeps a journal of what it did.
    final class StrictProxyBudgetManager {
        var store: any StrictProxyBudgetStore
        var validator: StrictProxyBudgetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any StrictProxyBudgetStore, validator: StrictProxyBudgetValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("strict proxy budget \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictProxyBudgetStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict proxy budget \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictProxyBudgetStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newStrictProxyBudgetManager(_ store: any StrictProxyBudgetStore, clock: any Kit.Clocks.Clock) -> StrictProxyBudgetManager {
        return StrictProxyBudgetManager(
            store: store,
            validator: defaultStrictProxyBudgetValidator(),
            clock: clock,
            journal: []
        )
    }
}
