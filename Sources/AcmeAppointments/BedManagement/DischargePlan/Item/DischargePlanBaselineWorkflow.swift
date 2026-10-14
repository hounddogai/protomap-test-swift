import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves discharge plan baselines through their life cycle and keeps a journal of what it did.
    final class DischargePlanBaselineWorkflow {
        var store: any DischargePlanBaselineStore
        var validator: DischargePlanBaselineValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DischargePlanBaselineEngine

        init(store: any DischargePlanBaselineStore, validator: DischargePlanBaselineValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DischargePlanBaselineEngine) {
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
                throw Kit.Failure("discharge plan baseline \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DischargePlanBaselineStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("discharge plan baseline \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DischargePlanBaselineStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("discharge plan baseline \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newDischargePlanBaselineWorkflow(_ store: any DischargePlanBaselineStore, clock: any Kit.Clocks.Clock) -> DischargePlanBaselineWorkflow {
        return DischargePlanBaselineWorkflow(
            store: store,
            validator: defaultDischargePlanBaselineValidator(),
            clock: clock,
            journal: [],
            engine: defaultDischargePlanBaselineEngine()
        )
    }
}
