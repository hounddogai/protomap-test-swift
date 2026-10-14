import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves cleaning budgets through their life cycle and keeps a journal of what it did.
    final class CleaningBudgetService {
        var store: any CleaningBudgetStore
        var validator: CleaningBudgetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CleaningBudgetEngine

        init(store: any CleaningBudgetStore, validator: CleaningBudgetValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CleaningBudgetEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("cleaning budget \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CleaningBudgetStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("cleaning budget \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CleaningBudgetStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("cleaning budget \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newCleaningBudgetService(_ store: any CleaningBudgetStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CleaningBudgetService {
        return CleaningBudgetService(
            store: store,
            validator: defaultCleaningBudgetValidator(),
            clock: clock,
            journal: [],
            engine: defaultCleaningBudgetEngine(flags)
        )
    }
}
