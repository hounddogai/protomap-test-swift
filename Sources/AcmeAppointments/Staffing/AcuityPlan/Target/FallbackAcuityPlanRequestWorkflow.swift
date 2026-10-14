import AcmePlatform
import Foundation

extension Staffing {
    /// Moves fallback acuity plan requests through their life cycle and keeps a journal of what it did.
    final class FallbackAcuityPlanRequestWorkflow {
        var store: any FallbackAcuityPlanRequestStore
        var validator: FallbackAcuityPlanRequestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FallbackAcuityPlanRequestEngine

        init(store: any FallbackAcuityPlanRequestStore, validator: FallbackAcuityPlanRequestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FallbackAcuityPlanRequestEngine) {
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
                throw Kit.Failure("fallback acuity plan request \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackAcuityPlanRequestStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback acuity plan request \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackAcuityPlanRequestStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback acuity plan request \(code) not found")
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

    static func newFallbackAcuityPlanRequestWorkflow(_ store: any FallbackAcuityPlanRequestStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> FallbackAcuityPlanRequestWorkflow {
        return FallbackAcuityPlanRequestWorkflow(
            store: store,
            validator: defaultFallbackAcuityPlanRequestValidator(),
            clock: clock,
            journal: [],
            engine: defaultFallbackAcuityPlanRequestEngine(flags)
        )
    }
}
