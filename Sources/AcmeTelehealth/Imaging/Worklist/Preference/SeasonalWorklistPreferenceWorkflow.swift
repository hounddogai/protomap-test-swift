import AcmePlatform
import Foundation

extension Imaging {
    /// Moves seasonal worklist preferences through their life cycle and keeps a journal of what it did.
    final class SeasonalWorklistPreferenceCoordinator {
        var store: any SeasonalWorklistPreferenceStore
        var validator: SeasonalWorklistPreferenceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SeasonalWorklistPreferenceEngine

        init(store: any SeasonalWorklistPreferenceStore, validator: SeasonalWorklistPreferenceValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SeasonalWorklistPreferenceEngine) {
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
                throw Kit.Failure("seasonal worklist preference \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalWorklistPreferenceStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal worklist preference \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalWorklistPreferenceStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal worklist preference \(code) not found")
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

    static func newSeasonalWorklistPreferenceCoordinator(_ store: any SeasonalWorklistPreferenceStore, clock: any Kit.Clocks.Clock) -> SeasonalWorklistPreferenceCoordinator {
        return SeasonalWorklistPreferenceCoordinator(
            store: store,
            validator: defaultSeasonalWorklistPreferenceValidator(),
            clock: clock,
            journal: [],
            engine: defaultSeasonalWorklistPreferenceEngine()
        )
    }
}
