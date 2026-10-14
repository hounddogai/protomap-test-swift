import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves legacy order set thresholds through their life cycle and keeps a journal of what it did.
    final class LegacyOrderSetThresholdManager {
        var store: any LegacyOrderSetThresholdStore
        var validator: LegacyOrderSetThresholdValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LegacyOrderSetThresholdEngine

        init(store: any LegacyOrderSetThresholdStore, validator: LegacyOrderSetThresholdValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LegacyOrderSetThresholdEngine) {
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
                throw Kit.Failure("legacy order set threshold \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyOrderSetThresholdStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy order set threshold \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyOrderSetThresholdStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy order set threshold \(code) not found")
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

    static func newLegacyOrderSetThresholdManager(_ store: any LegacyOrderSetThresholdStore, clock: any Kit.Clocks.Clock) -> LegacyOrderSetThresholdManager {
        return LegacyOrderSetThresholdManager(
            store: store,
            validator: defaultLegacyOrderSetThresholdValidator(),
            clock: clock,
            journal: [],
            engine: defaultLegacyOrderSetThresholdEngine()
        )
    }
}
