import AcmePlatform
import Foundation

extension Referrals {
    /// Moves seasonal closure metrics through their life cycle and keeps a journal of what it did.
    final class SeasonalClosureMetricService {
        var store: any SeasonalClosureMetricStore
        var validator: SeasonalClosureMetricValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SeasonalClosureMetricEngine

        init(store: any SeasonalClosureMetricStore, validator: SeasonalClosureMetricValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SeasonalClosureMetricEngine) {
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
                throw Kit.Failure("seasonal closure metric \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalClosureMetricStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal closure metric \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalClosureMetricStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal closure metric \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newSeasonalClosureMetricService(_ store: any SeasonalClosureMetricStore, clock: any Kit.Clocks.Clock) -> SeasonalClosureMetricService {
        return SeasonalClosureMetricService(
            store: store,
            validator: defaultSeasonalClosureMetricValidator(),
            clock: clock,
            journal: [],
            engine: defaultSeasonalClosureMetricEngine()
        )
    }
}
