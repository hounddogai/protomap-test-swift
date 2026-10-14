import AcmePlatform
import Foundation

extension Imaging {
    /// Moves seasonal modality quotas through their life cycle and keeps a journal of what it did.
    final class SeasonalModalityQuotaCoordinator {
        var store: any SeasonalModalityQuotaStore
        var validator: SeasonalModalityQuotaValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SeasonalModalityQuotaEngine

        init(store: any SeasonalModalityQuotaStore, validator: SeasonalModalityQuotaValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SeasonalModalityQuotaEngine) {
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
                throw Kit.Failure("seasonal modality quota \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalModalityQuotaStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal modality quota \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalModalityQuotaStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal modality quota \(code) not found")
            }
            let result = engine.run(item)
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

    static func newSeasonalModalityQuotaCoordinator(_ store: any SeasonalModalityQuotaStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> SeasonalModalityQuotaCoordinator {
        return SeasonalModalityQuotaCoordinator(
            store: store,
            validator: defaultSeasonalModalityQuotaValidator(),
            clock: clock,
            journal: [],
            engine: defaultSeasonalModalityQuotaEngine(flags)
        )
    }
}
