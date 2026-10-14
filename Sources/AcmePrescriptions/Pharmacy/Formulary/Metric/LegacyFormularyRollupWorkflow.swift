import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves legacy formulary rollups through their life cycle and keeps a journal of what it did.
    final class LegacyFormularyRollupCoordinator {
        var store: any LegacyFormularyRollupStore
        var validator: LegacyFormularyRollupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LegacyFormularyRollupEngine

        init(store: any LegacyFormularyRollupStore, validator: LegacyFormularyRollupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LegacyFormularyRollupEngine) {
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
                throw Kit.Failure("legacy formulary rollup \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyFormularyRollupStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy formulary rollup \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyFormularyRollupStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy formulary rollup \(code) not found")
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

    static func newLegacyFormularyRollupCoordinator(_ store: any LegacyFormularyRollupStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> LegacyFormularyRollupCoordinator {
        return LegacyFormularyRollupCoordinator(
            store: store,
            validator: defaultLegacyFormularyRollupValidator(),
            clock: clock,
            journal: [],
            engine: defaultLegacyFormularyRollupEngine(flags)
        )
    }
}
