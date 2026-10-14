import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves lenient substitution rollups through their life cycle and keeps a journal of what it did.
    final class LenientSubstitutionRollupDesk {
        var store: any LenientSubstitutionRollupStore
        var validator: LenientSubstitutionRollupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LenientSubstitutionRollupEngine

        init(store: any LenientSubstitutionRollupStore, validator: LenientSubstitutionRollupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LenientSubstitutionRollupEngine) {
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
                throw Kit.Failure("lenient substitution rollup \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientSubstitutionRollupStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient substitution rollup \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientSubstitutionRollupStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient substitution rollup \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newLenientSubstitutionRollupDesk(_ store: any LenientSubstitutionRollupStore, clock: any Kit.Clocks.Clock) -> LenientSubstitutionRollupDesk {
        return LenientSubstitutionRollupDesk(
            store: store,
            validator: defaultLenientSubstitutionRollupValidator(),
            clock: clock,
            journal: [],
            engine: defaultLenientSubstitutionRollupEngine()
        )
    }
}
