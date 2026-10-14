import AcmePlatform
import Foundation

extension Staffing {
    /// Moves global acuity plan rules through their life cycle and keeps a journal of what it did.
    final class GlobalAcuityPlanRuleManager {
        var store: any GlobalAcuityPlanRuleStore
        var validator: GlobalAcuityPlanRuleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GlobalAcuityPlanRuleEngine

        init(store: any GlobalAcuityPlanRuleStore, validator: GlobalAcuityPlanRuleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GlobalAcuityPlanRuleEngine) {
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
                throw Kit.Failure("global acuity plan rule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalAcuityPlanRuleStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global acuity plan rule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalAcuityPlanRuleStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("global acuity plan rule \(code) not found")
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

    static func newGlobalAcuityPlanRuleManager(_ store: any GlobalAcuityPlanRuleStore, clock: any Kit.Clocks.Clock) -> GlobalAcuityPlanRuleManager {
        return GlobalAcuityPlanRuleManager(
            store: store,
            validator: defaultGlobalAcuityPlanRuleValidator(),
            clock: clock,
            journal: [],
            engine: defaultGlobalAcuityPlanRuleEngine()
        )
    }
}
