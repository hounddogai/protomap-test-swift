import AcmePlatform
import Foundation

extension Consent {
    /// Moves seasonal language checkpoints through their life cycle and keeps a journal of what it did.
    final class SeasonalLanguageCheckpointCoordinator {
        var store: any SeasonalLanguageCheckpointStore
        var validator: SeasonalLanguageCheckpointValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SeasonalLanguageCheckpointEngine

        init(store: any SeasonalLanguageCheckpointStore, validator: SeasonalLanguageCheckpointValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SeasonalLanguageCheckpointEngine) {
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
                throw Kit.Failure("seasonal language checkpoint \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalLanguageCheckpointStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal language checkpoint \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalLanguageCheckpointStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal language checkpoint \(code) not found")
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

    static func newSeasonalLanguageCheckpointCoordinator(_ store: any SeasonalLanguageCheckpointStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> SeasonalLanguageCheckpointCoordinator {
        return SeasonalLanguageCheckpointCoordinator(
            store: store,
            validator: defaultSeasonalLanguageCheckpointValidator(),
            clock: clock,
            journal: [],
            engine: defaultSeasonalLanguageCheckpointEngine(flags)
        )
    }
}
