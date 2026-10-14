import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves seasonal formulary segments through their life cycle and keeps a journal of what it did.
    final class SeasonalFormularySegmentManager {
        var store: any SeasonalFormularySegmentStore
        var validator: SeasonalFormularySegmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SeasonalFormularySegmentEngine

        init(store: any SeasonalFormularySegmentStore, validator: SeasonalFormularySegmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SeasonalFormularySegmentEngine) {
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
                throw Kit.Failure("seasonal formulary segment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalFormularySegmentStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal formulary segment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalFormularySegmentStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal formulary segment \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newSeasonalFormularySegmentManager(_ store: any SeasonalFormularySegmentStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> SeasonalFormularySegmentManager {
        return SeasonalFormularySegmentManager(
            store: store,
            validator: defaultSeasonalFormularySegmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultSeasonalFormularySegmentEngine(flags)
        )
    }
}
