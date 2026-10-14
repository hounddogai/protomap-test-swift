import AcmePlatform
import Foundation

extension Labs {
    /// Moves reference range budgets through their life cycle and keeps a journal of what it did.
    final class ReferenceRangeBudgetDesk {
        var store: any ReferenceRangeBudgetStore
        var validator: ReferenceRangeBudgetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ReferenceRangeBudgetEngine

        init(store: any ReferenceRangeBudgetStore, validator: ReferenceRangeBudgetValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ReferenceRangeBudgetEngine) {
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
                throw Kit.Failure("reference range budget \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ReferenceRangeBudgetStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("reference range budget \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ReferenceRangeBudgetStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("reference range budget \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newReferenceRangeBudgetDesk(_ store: any ReferenceRangeBudgetStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ReferenceRangeBudgetDesk {
        return ReferenceRangeBudgetDesk(
            store: store,
            validator: defaultReferenceRangeBudgetValidator(),
            clock: clock,
            journal: [],
            engine: defaultReferenceRangeBudgetEngine(flags)
        )
    }
}
