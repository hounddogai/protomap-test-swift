import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves seasonal substitution quotas through their life cycle and keeps a journal of what it did.
    final class SeasonalSubstitutionQuotaWorkflow {
        var store: any SeasonalSubstitutionQuotaStore
        var validator: SeasonalSubstitutionQuotaValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SeasonalSubstitutionQuotaEngine

        init(store: any SeasonalSubstitutionQuotaStore, validator: SeasonalSubstitutionQuotaValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SeasonalSubstitutionQuotaEngine) {
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
                throw Kit.Failure("seasonal substitution quota \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalSubstitutionQuotaStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal substitution quota \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalSubstitutionQuotaStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal substitution quota \(code) not found")
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

    static func newSeasonalSubstitutionQuotaWorkflow(_ store: any SeasonalSubstitutionQuotaStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> SeasonalSubstitutionQuotaWorkflow {
        return SeasonalSubstitutionQuotaWorkflow(
            store: store,
            validator: defaultSeasonalSubstitutionQuotaValidator(),
            clock: clock,
            journal: [],
            engine: defaultSeasonalSubstitutionQuotaEngine(flags)
        )
    }
}
