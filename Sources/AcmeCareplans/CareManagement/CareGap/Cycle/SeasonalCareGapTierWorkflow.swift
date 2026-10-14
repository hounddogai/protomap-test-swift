import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves seasonal care gap tiers through their life cycle and keeps a journal of what it did.
    final class SeasonalCareGapTierCoordinator {
        var store: any SeasonalCareGapTierStore
        var validator: SeasonalCareGapTierValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SeasonalCareGapTierEngine

        init(store: any SeasonalCareGapTierStore, validator: SeasonalCareGapTierValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SeasonalCareGapTierEngine) {
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
                throw Kit.Failure("seasonal care gap tier \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalCareGapTierStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal care gap tier \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalCareGapTierStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal care gap tier \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newSeasonalCareGapTierCoordinator(_ store: any SeasonalCareGapTierStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> SeasonalCareGapTierCoordinator {
        return SeasonalCareGapTierCoordinator(
            store: store,
            validator: defaultSeasonalCareGapTierValidator(),
            clock: clock,
            journal: [],
            engine: defaultSeasonalCareGapTierEngine(flags)
        )
    }
}
