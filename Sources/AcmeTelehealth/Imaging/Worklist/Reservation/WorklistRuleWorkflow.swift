import AcmePlatform
import Foundation

extension Imaging {
    /// Moves worklist rules through their life cycle and keeps a journal of what it did.
    final class WorklistRuleService {
        var store: any WorklistRuleStore
        var validator: WorklistRuleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WorklistRuleEngine

        init(store: any WorklistRuleStore, validator: WorklistRuleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WorklistRuleEngine) {
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
                throw Kit.Failure("worklist rule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WorklistRuleStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("worklist rule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WorklistRuleStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("worklist rule \(code) not found")
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

    static func newWorklistRuleService(_ store: any WorklistRuleStore, clock: any Kit.Clocks.Clock) -> WorklistRuleService {
        return WorklistRuleService(
            store: store,
            validator: defaultWorklistRuleValidator(),
            clock: clock,
            journal: [],
            engine: defaultWorklistRuleEngine()
        )
    }
}
