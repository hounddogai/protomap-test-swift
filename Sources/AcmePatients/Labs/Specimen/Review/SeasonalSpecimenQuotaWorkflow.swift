import AcmePlatform
import Foundation

extension Labs {
    /// Moves seasonal specimen quotas through their life cycle and keeps a journal of what it did.
    final class SeasonalSpecimenQuotaWorkflow {
        var store: any SeasonalSpecimenQuotaStore
        var validator: SeasonalSpecimenQuotaValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SeasonalSpecimenQuotaEngine

        init(store: any SeasonalSpecimenQuotaStore, validator: SeasonalSpecimenQuotaValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SeasonalSpecimenQuotaEngine) {
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
                throw Kit.Failure("seasonal specimen quota \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalSpecimenQuotaStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal specimen quota \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalSpecimenQuotaStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal specimen quota \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newSeasonalSpecimenQuotaWorkflow(_ store: any SeasonalSpecimenQuotaStore, clock: any Kit.Clocks.Clock) -> SeasonalSpecimenQuotaWorkflow {
        return SeasonalSpecimenQuotaWorkflow(
            store: store,
            validator: defaultSeasonalSpecimenQuotaValidator(),
            clock: clock,
            journal: [],
            engine: defaultSeasonalSpecimenQuotaEngine()
        )
    }
}
