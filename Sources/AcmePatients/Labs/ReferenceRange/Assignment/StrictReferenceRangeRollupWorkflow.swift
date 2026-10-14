import AcmePlatform
import Foundation

extension Labs {
    /// Moves strict reference range rollups through their life cycle and keeps a journal of what it did.
    final class StrictReferenceRangeRollupDesk {
        var store: any StrictReferenceRangeRollupStore
        var validator: StrictReferenceRangeRollupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: StrictReferenceRangeRollupEngine

        init(store: any StrictReferenceRangeRollupStore, validator: StrictReferenceRangeRollupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: StrictReferenceRangeRollupEngine) {
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
                throw Kit.Failure("strict reference range rollup \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictReferenceRangeRollupStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict reference range rollup \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictReferenceRangeRollupStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict reference range rollup \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newStrictReferenceRangeRollupDesk(_ store: any StrictReferenceRangeRollupStore, clock: any Kit.Clocks.Clock) -> StrictReferenceRangeRollupDesk {
        return StrictReferenceRangeRollupDesk(
            store: store,
            validator: defaultStrictReferenceRangeRollupValidator(),
            clock: clock,
            journal: [],
            engine: defaultStrictReferenceRangeRollupEngine()
        )
    }
}
