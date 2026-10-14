import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves bed board budgets through their life cycle and keeps a journal of what it did.
    final class BedBoardBudgetDesk {
        var store: any BedBoardBudgetStore
        var validator: BedBoardBudgetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BedBoardBudgetEngine

        init(store: any BedBoardBudgetStore, validator: BedBoardBudgetValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BedBoardBudgetEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("bed board budget \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BedBoardBudgetStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("bed board budget \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BedBoardBudgetStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("bed board budget \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newBedBoardBudgetDesk(_ store: any BedBoardBudgetStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> BedBoardBudgetDesk {
        return BedBoardBudgetDesk(
            store: store,
            validator: defaultBedBoardBudgetValidator(),
            clock: clock,
            journal: [],
            engine: defaultBedBoardBudgetEngine(flags)
        )
    }
}
