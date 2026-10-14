import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves care protocol plans through their life cycle and keeps a journal of what it did.
    final class CareProtocolPlanWorkflow {
        var store: any CareProtocolPlanStore
        var validator: CareProtocolPlanValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CareProtocolPlanEngine

        init(store: any CareProtocolPlanStore, validator: CareProtocolPlanValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CareProtocolPlanEngine) {
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
                throw Kit.Failure("care protocol plan \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CareProtocolPlanStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care protocol plan \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CareProtocolPlanStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("care protocol plan \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newCareProtocolPlanWorkflow(_ store: any CareProtocolPlanStore, clock: any Kit.Clocks.Clock) -> CareProtocolPlanWorkflow {
        return CareProtocolPlanWorkflow(
            store: store,
            validator: defaultCareProtocolPlanValidator(),
            clock: clock,
            journal: [],
            engine: defaultCareProtocolPlanEngine()
        )
    }
}
