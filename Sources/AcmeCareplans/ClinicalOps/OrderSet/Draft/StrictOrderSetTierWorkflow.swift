import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves strict order set tiers through their life cycle and keeps a journal of what it did.
    final class StrictOrderSetTierWorkflow {
        var store: any StrictOrderSetTierStore
        var validator: StrictOrderSetTierValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: StrictOrderSetTierEngine

        init(store: any StrictOrderSetTierStore, validator: StrictOrderSetTierValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: StrictOrderSetTierEngine) {
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
                throw Kit.Failure("strict order set tier \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictOrderSetTierStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict order set tier \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictOrderSetTierStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict order set tier \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newStrictOrderSetTierWorkflow(_ store: any StrictOrderSetTierStore, clock: any Kit.Clocks.Clock) -> StrictOrderSetTierWorkflow {
        return StrictOrderSetTierWorkflow(
            store: store,
            validator: defaultStrictOrderSetTierValidator(),
            clock: clock,
            journal: [],
            engine: defaultStrictOrderSetTierEngine()
        )
    }
}
