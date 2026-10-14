import AcmePlatform
import Foundation

extension Imaging {
    /// Moves tiered study rules through their life cycle and keeps a journal of what it did.
    final class TieredStudyRuleWorkflow {
        var store: any TieredStudyRuleStore
        var validator: TieredStudyRuleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TieredStudyRuleEngine

        init(store: any TieredStudyRuleStore, validator: TieredStudyRuleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TieredStudyRuleEngine) {
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
                throw Kit.Failure("tiered study rule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredStudyRuleStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered study rule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredStudyRuleStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered study rule \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newTieredStudyRuleWorkflow(_ store: any TieredStudyRuleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> TieredStudyRuleWorkflow {
        return TieredStudyRuleWorkflow(
            store: store,
            validator: defaultTieredStudyRuleValidator(),
            clock: clock,
            journal: [],
            engine: defaultTieredStudyRuleEngine(flags)
        )
    }
}
