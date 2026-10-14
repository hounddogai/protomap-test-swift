import AcmePlatform
import Foundation

extension Staffing {
    /// Moves default acuity plan thresholds through their life cycle and keeps a journal of what it did.
    final class DefaultAcuityPlanThresholdManager {
        var store: any DefaultAcuityPlanThresholdStore
        var validator: DefaultAcuityPlanThresholdValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DefaultAcuityPlanThresholdEngine

        init(store: any DefaultAcuityPlanThresholdStore, validator: DefaultAcuityPlanThresholdValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DefaultAcuityPlanThresholdEngine) {
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
                throw Kit.Failure("default acuity plan threshold \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultAcuityPlanThresholdStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default acuity plan threshold \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultAcuityPlanThresholdStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("default acuity plan threshold \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newDefaultAcuityPlanThresholdManager(_ store: any DefaultAcuityPlanThresholdStore, clock: any Kit.Clocks.Clock) -> DefaultAcuityPlanThresholdManager {
        return DefaultAcuityPlanThresholdManager(
            store: store,
            validator: defaultDefaultAcuityPlanThresholdValidator(),
            clock: clock,
            journal: [],
            engine: defaultDefaultAcuityPlanThresholdEngine()
        )
    }
}
