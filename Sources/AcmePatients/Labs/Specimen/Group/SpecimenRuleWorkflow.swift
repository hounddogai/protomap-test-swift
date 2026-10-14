import AcmePlatform
import Foundation

extension Labs {
    /// Moves specimen rules through their life cycle and keeps a journal of what it did.
    final class SpecimenRuleWorkflow {
        var store: any SpecimenRuleStore
        var validator: SpecimenRuleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SpecimenRuleEngine

        init(store: any SpecimenRuleStore, validator: SpecimenRuleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SpecimenRuleEngine) {
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
                throw Kit.Failure("specimen rule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SpecimenRuleStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("specimen rule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SpecimenRuleStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("specimen rule \(code) not found")
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

    static func newSpecimenRuleWorkflow(_ store: any SpecimenRuleStore, clock: any Kit.Clocks.Clock) -> SpecimenRuleWorkflow {
        return SpecimenRuleWorkflow(
            store: store,
            validator: defaultSpecimenRuleValidator(),
            clock: clock,
            journal: [],
            engine: defaultSpecimenRuleEngine()
        )
    }
}
