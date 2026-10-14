import AcmePlatform
import Foundation

extension Imaging {
    /// Moves strict priority plans through their life cycle and keeps a journal of what it did.
    final class StrictPriorityPlanDesk {
        var store: any StrictPriorityPlanStore
        var validator: StrictPriorityPlanValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: StrictPriorityPlanEngine

        init(store: any StrictPriorityPlanStore, validator: StrictPriorityPlanValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: StrictPriorityPlanEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict priority plan \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictPriorityPlanStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict priority plan \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictPriorityPlanStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict priority plan \(code) not found")
            }
            let result = engine.price(item)
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

    static func newStrictPriorityPlanDesk(_ store: any StrictPriorityPlanStore, clock: any Kit.Clocks.Clock) -> StrictPriorityPlanDesk {
        return StrictPriorityPlanDesk(
            store: store,
            validator: defaultStrictPriorityPlanValidator(),
            clock: clock,
            journal: [],
            engine: defaultStrictPriorityPlanEngine()
        )
    }
}
