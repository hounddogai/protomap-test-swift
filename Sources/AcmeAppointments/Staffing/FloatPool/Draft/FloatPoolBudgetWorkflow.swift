import AcmePlatform
import Foundation

extension Staffing {
    /// Moves float pool budgets through their life cycle and keeps a journal of what it did.
    final class FloatPoolBudgetCoordinator {
        var store: any FloatPoolBudgetStore
        var validator: FloatPoolBudgetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any FloatPoolBudgetStore, validator: FloatPoolBudgetValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("float pool budget \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FloatPoolBudgetStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("float pool budget \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FloatPoolBudgetStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
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

    static func newFloatPoolBudgetCoordinator(_ store: any FloatPoolBudgetStore, clock: any Kit.Clocks.Clock) -> FloatPoolBudgetCoordinator {
        return FloatPoolBudgetCoordinator(
            store: store,
            validator: defaultFloatPoolBudgetValidator(),
            clock: clock,
            journal: []
        )
    }
}
