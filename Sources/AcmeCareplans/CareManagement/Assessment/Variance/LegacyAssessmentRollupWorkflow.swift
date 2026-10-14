import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves legacy assessment rollups through their life cycle and keeps a journal of what it did.
    final class LegacyAssessmentRollupWorkflow {
        var store: any LegacyAssessmentRollupStore
        var validator: LegacyAssessmentRollupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LegacyAssessmentRollupEngine

        init(store: any LegacyAssessmentRollupStore, validator: LegacyAssessmentRollupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LegacyAssessmentRollupEngine) {
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
                throw Kit.Failure("legacy assessment rollup \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyAssessmentRollupStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy assessment rollup \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyAssessmentRollupStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy assessment rollup \(code) not found")
            }
            let result = engine.price(item)
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

    static func newLegacyAssessmentRollupWorkflow(_ store: any LegacyAssessmentRollupStore, clock: any Kit.Clocks.Clock) -> LegacyAssessmentRollupWorkflow {
        return LegacyAssessmentRollupWorkflow(
            store: store,
            validator: defaultLegacyAssessmentRollupValidator(),
            clock: clock,
            journal: [],
            engine: defaultLegacyAssessmentRollupEngine()
        )
    }
}
