import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves rolling discharge plan rules through their life cycle and keeps a journal of what it did.
    final class RollingDischargePlanRuleCoordinator {
        var store: any RollingDischargePlanRuleStore
        var validator: RollingDischargePlanRuleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RollingDischargePlanRuleEngine

        init(store: any RollingDischargePlanRuleStore, validator: RollingDischargePlanRuleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RollingDischargePlanRuleEngine) {
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
                throw Kit.Failure("rolling discharge plan rule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingDischargePlanRuleStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling discharge plan rule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingDischargePlanRuleStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling discharge plan rule \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
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

    static func newRollingDischargePlanRuleCoordinator(_ store: any RollingDischargePlanRuleStore, clock: any Kit.Clocks.Clock) -> RollingDischargePlanRuleCoordinator {
        return RollingDischargePlanRuleCoordinator(
            store: store,
            validator: defaultRollingDischargePlanRuleValidator(),
            clock: clock,
            journal: [],
            engine: defaultRollingDischargePlanRuleEngine()
        )
    }
}
