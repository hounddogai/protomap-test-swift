import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves weighted formulary groups through their life cycle and keeps a journal of what it did.
    final class WeightedFormularyGroupCoordinator {
        var store: any WeightedFormularyGroupStore
        var validator: WeightedFormularyGroupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WeightedFormularyGroupEngine

        init(store: any WeightedFormularyGroupStore, validator: WeightedFormularyGroupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WeightedFormularyGroupEngine) {
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
                throw Kit.Failure("weighted formulary group \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedFormularyGroupStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted formulary group \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedFormularyGroupStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted formulary group \(code) not found")
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

    static func newWeightedFormularyGroupCoordinator(_ store: any WeightedFormularyGroupStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> WeightedFormularyGroupCoordinator {
        return WeightedFormularyGroupCoordinator(
            store: store,
            validator: defaultWeightedFormularyGroupValidator(),
            clock: clock,
            journal: [],
            engine: defaultWeightedFormularyGroupEngine(flags)
        )
    }
}
