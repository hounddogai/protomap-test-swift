import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves fallback goal rollups through their life cycle and keeps a journal of what it did.
    final class FallbackGoalRollupDesk {
        var store: any FallbackGoalRollupStore
        var validator: FallbackGoalRollupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FallbackGoalRollupEngine

        init(store: any FallbackGoalRollupStore, validator: FallbackGoalRollupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FallbackGoalRollupEngine) {
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
                throw Kit.Failure("fallback goal rollup \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackGoalRollupStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback goal rollup \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackGoalRollupStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback goal rollup \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newFallbackGoalRollupDesk(_ store: any FallbackGoalRollupStore, clock: any Kit.Clocks.Clock) -> FallbackGoalRollupDesk {
        return FallbackGoalRollupDesk(
            store: store,
            validator: defaultFallbackGoalRollupValidator(),
            clock: clock,
            journal: [],
            engine: defaultFallbackGoalRollupEngine()
        )
    }
}
