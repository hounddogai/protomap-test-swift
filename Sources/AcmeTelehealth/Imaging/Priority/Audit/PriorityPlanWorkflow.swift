import AcmePlatform
import Foundation

extension Imaging {
    /// Moves priority plans through their life cycle and keeps a journal of what it did.
    final class PriorityPlanWorkflow {
        var store: any PriorityPlanStore
        var validator: PriorityPlanValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PriorityPlanEngine

        init(store: any PriorityPlanStore, validator: PriorityPlanValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PriorityPlanEngine) {
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
                throw Kit.Failure("priority plan \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PriorityPlanStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("priority plan \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PriorityPlanStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("priority plan \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newPriorityPlanWorkflow(_ store: any PriorityPlanStore, clock: any Kit.Clocks.Clock) -> PriorityPlanWorkflow {
        return PriorityPlanWorkflow(
            store: store,
            validator: defaultPriorityPlanValidator(),
            clock: clock,
            journal: [],
            engine: defaultPriorityPlanEngine()
        )
    }
}
