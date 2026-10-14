import AcmePlatform
import Foundation

extension Labs {
    /// Moves weighted courier overrides through their life cycle and keeps a journal of what it did.
    final class WeightedCourierOverrideWorkflow {
        var store: any WeightedCourierOverrideStore
        var validator: WeightedCourierOverrideValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WeightedCourierOverrideEngine

        init(store: any WeightedCourierOverrideStore, validator: WeightedCourierOverrideValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WeightedCourierOverrideEngine) {
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
                throw Kit.Failure("weighted courier override \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedCourierOverrideStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted courier override \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedCourierOverrideStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted courier override \(code) not found")
            }
            let result = engine.price(item)
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

    static func newWeightedCourierOverrideWorkflow(_ store: any WeightedCourierOverrideStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> WeightedCourierOverrideWorkflow {
        return WeightedCourierOverrideWorkflow(
            store: store,
            validator: defaultWeightedCourierOverrideValidator(),
            clock: clock,
            journal: [],
            engine: defaultWeightedCourierOverrideEngine(flags)
        )
    }
}
