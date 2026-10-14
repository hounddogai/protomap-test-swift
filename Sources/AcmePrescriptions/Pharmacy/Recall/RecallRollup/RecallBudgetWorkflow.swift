import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves recall budgets through their life cycle and keeps a journal of what it did.
    final class RecallBudgetService {
        var store: any RecallBudgetStore
        var validator: RecallBudgetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RecallBudgetStore, validator: RecallBudgetValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("recall budget \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RecallBudgetStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("recall budget \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RecallBudgetStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newRecallBudgetService(_ store: any RecallBudgetStore, clock: any Kit.Clocks.Clock) -> RecallBudgetService {
        return RecallBudgetService(
            store: store,
            validator: defaultRecallBudgetValidator(),
            clock: clock,
            journal: []
        )
    }
}
