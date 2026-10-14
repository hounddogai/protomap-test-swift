import AcmePlatform
import Foundation

extension Labs {
    /// Moves global specimen rules through their life cycle and keeps a journal of what it did.
    final class GlobalSpecimenRuleWorkflow {
        var store: any GlobalSpecimenRuleStore
        var validator: GlobalSpecimenRuleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GlobalSpecimenRuleEngine

        init(store: any GlobalSpecimenRuleStore, validator: GlobalSpecimenRuleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GlobalSpecimenRuleEngine) {
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
                throw Kit.Failure("global specimen rule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalSpecimenRuleStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global specimen rule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalSpecimenRuleStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("global specimen rule \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newGlobalSpecimenRuleWorkflow(_ store: any GlobalSpecimenRuleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> GlobalSpecimenRuleWorkflow {
        return GlobalSpecimenRuleWorkflow(
            store: store,
            validator: defaultGlobalSpecimenRuleValidator(),
            clock: clock,
            journal: [],
            engine: defaultGlobalSpecimenRuleEngine(flags)
        )
    }
}
