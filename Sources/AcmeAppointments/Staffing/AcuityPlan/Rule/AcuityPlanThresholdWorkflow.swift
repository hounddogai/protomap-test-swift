import AcmePlatform
import Foundation

extension Staffing {
    /// Moves acuity plan thresholds through their life cycle and keeps a journal of what it did.
    final class AcuityPlanThresholdWorkflow {
        var store: any AcuityPlanThresholdStore
        var validator: AcuityPlanThresholdValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AcuityPlanThresholdEngine

        init(store: any AcuityPlanThresholdStore, validator: AcuityPlanThresholdValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AcuityPlanThresholdEngine) {
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
                throw Kit.Failure("acuity plan threshold \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AcuityPlanThresholdStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("acuity plan threshold \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AcuityPlanThresholdStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("acuity plan threshold \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newAcuityPlanThresholdWorkflow(_ store: any AcuityPlanThresholdStore, clock: any Kit.Clocks.Clock) -> AcuityPlanThresholdWorkflow {
        return AcuityPlanThresholdWorkflow(
            store: store,
            validator: defaultAcuityPlanThresholdValidator(),
            clock: clock,
            journal: [],
            engine: defaultAcuityPlanThresholdEngine()
        )
    }
}
