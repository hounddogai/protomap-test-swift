import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves weighted recall cycles through their life cycle and keeps a journal of what it did.
    final class WeightedRecallCycleService {
        var store: any WeightedRecallCycleStore
        var validator: WeightedRecallCycleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WeightedRecallCycleEngine

        init(store: any WeightedRecallCycleStore, validator: WeightedRecallCycleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WeightedRecallCycleEngine) {
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
                throw Kit.Failure("weighted recall cycle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedRecallCycleStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted recall cycle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedRecallCycleStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted recall cycle \(code) not found")
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

    static func newWeightedRecallCycleService(_ store: any WeightedRecallCycleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> WeightedRecallCycleService {
        return WeightedRecallCycleService(
            store: store,
            validator: defaultWeightedRecallCycleValidator(),
            clock: clock,
            journal: [],
            engine: defaultWeightedRecallCycleEngine(flags)
        )
    }
}
