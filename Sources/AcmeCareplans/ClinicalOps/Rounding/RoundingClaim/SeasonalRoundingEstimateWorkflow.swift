import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves seasonal rounding estimates through their life cycle and keeps a journal of what it did.
    final class SeasonalRoundingEstimateWorkflow {
        var store: any SeasonalRoundingEstimateStore
        var validator: SeasonalRoundingEstimateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SeasonalRoundingEstimateEngine

        init(store: any SeasonalRoundingEstimateStore, validator: SeasonalRoundingEstimateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SeasonalRoundingEstimateEngine) {
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
                throw Kit.Failure("seasonal rounding estimate \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalRoundingEstimateStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal rounding estimate \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalRoundingEstimateStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal rounding estimate \(code) not found")
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

    static func newSeasonalRoundingEstimateWorkflow(_ store: any SeasonalRoundingEstimateStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> SeasonalRoundingEstimateWorkflow {
        return SeasonalRoundingEstimateWorkflow(
            store: store,
            validator: defaultSeasonalRoundingEstimateValidator(),
            clock: clock,
            journal: [],
            engine: defaultSeasonalRoundingEstimateEngine(flags)
        )
    }
}
