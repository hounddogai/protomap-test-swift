import AcmePlatform
import Foundation

extension Imaging {
    /// Moves tiered study budgets through their life cycle and keeps a journal of what it did.
    final class TieredStudyBudgetCoordinator {
        var store: any TieredStudyBudgetStore
        var validator: TieredStudyBudgetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any TieredStudyBudgetStore, validator: TieredStudyBudgetValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("tiered study budget \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredStudyBudgetStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered study budget \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredStudyBudgetStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
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

    static func newTieredStudyBudgetCoordinator(_ store: any TieredStudyBudgetStore, clock: any Kit.Clocks.Clock) -> TieredStudyBudgetCoordinator {
        return TieredStudyBudgetCoordinator(
            store: store,
            validator: defaultTieredStudyBudgetValidator(),
            clock: clock,
            journal: []
        )
    }
}
