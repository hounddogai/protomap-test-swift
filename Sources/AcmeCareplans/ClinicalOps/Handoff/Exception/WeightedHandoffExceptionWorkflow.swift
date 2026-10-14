import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves weighted handoff exceptions through their life cycle and keeps a journal of what it did.
    final class WeightedHandoffExceptionWorkflow {
        var store: any WeightedHandoffExceptionStore
        var validator: WeightedHandoffExceptionValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WeightedHandoffExceptionEngine

        init(store: any WeightedHandoffExceptionStore, validator: WeightedHandoffExceptionValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WeightedHandoffExceptionEngine) {
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
                throw Kit.Failure("weighted handoff exception \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedHandoffExceptionStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted handoff exception \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedHandoffExceptionStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted handoff exception \(code) not found")
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
                if item.createdAt > cutoff {
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

    static func newWeightedHandoffExceptionWorkflow(_ store: any WeightedHandoffExceptionStore, clock: any Kit.Clocks.Clock) -> WeightedHandoffExceptionWorkflow {
        return WeightedHandoffExceptionWorkflow(
            store: store,
            validator: defaultWeightedHandoffExceptionValidator(),
            clock: clock,
            journal: [],
            engine: defaultWeightedHandoffExceptionEngine()
        )
    }
}
