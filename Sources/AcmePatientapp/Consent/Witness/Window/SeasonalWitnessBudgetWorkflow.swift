import AcmePlatform
import Foundation

extension Consent {
    /// Moves seasonal witness budgets through their life cycle and keeps a journal of what it did.
    final class SeasonalWitnessBudgetManager {
        var store: any SeasonalWitnessBudgetStore
        var validator: SeasonalWitnessBudgetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SeasonalWitnessBudgetEngine

        init(store: any SeasonalWitnessBudgetStore, validator: SeasonalWitnessBudgetValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SeasonalWitnessBudgetEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal witness budget \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalWitnessBudgetStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal witness budget \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalWitnessBudgetStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal witness budget \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newSeasonalWitnessBudgetManager(_ store: any SeasonalWitnessBudgetStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> SeasonalWitnessBudgetManager {
        return SeasonalWitnessBudgetManager(
            store: store,
            validator: defaultSeasonalWitnessBudgetValidator(),
            clock: clock,
            journal: [],
            engine: defaultSeasonalWitnessBudgetEngine(flags)
        )
    }
}
