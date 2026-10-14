import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves rolling substitution rules through their life cycle and keeps a journal of what it did.
    final class RollingSubstitutionRuleWorkflow {
        var store: any RollingSubstitutionRuleStore
        var validator: RollingSubstitutionRuleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RollingSubstitutionRuleEngine

        init(store: any RollingSubstitutionRuleStore, validator: RollingSubstitutionRuleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RollingSubstitutionRuleEngine) {
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
                throw Kit.Failure("rolling substitution rule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingSubstitutionRuleStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling substitution rule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingSubstitutionRuleStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling substitution rule \(code) not found")
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
                if item.updatedAt > cutoff {
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

    static func newRollingSubstitutionRuleWorkflow(_ store: any RollingSubstitutionRuleStore, clock: any Kit.Clocks.Clock) -> RollingSubstitutionRuleWorkflow {
        return RollingSubstitutionRuleWorkflow(
            store: store,
            validator: defaultRollingSubstitutionRuleValidator(),
            clock: clock,
            journal: [],
            engine: defaultRollingSubstitutionRuleEngine()
        )
    }
}
