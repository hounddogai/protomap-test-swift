import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves capped assessment baselines through their life cycle and keeps a journal of what it did.
    final class CappedAssessmentBaselineDesk {
        var store: any CappedAssessmentBaselineStore
        var validator: CappedAssessmentBaselineValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CappedAssessmentBaselineEngine

        init(store: any CappedAssessmentBaselineStore, validator: CappedAssessmentBaselineValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CappedAssessmentBaselineEngine) {
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
                throw Kit.Failure("capped assessment baseline \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedAssessmentBaselineStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped assessment baseline \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedAssessmentBaselineStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped assessment baseline \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newCappedAssessmentBaselineDesk(_ store: any CappedAssessmentBaselineStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CappedAssessmentBaselineDesk {
        return CappedAssessmentBaselineDesk(
            store: store,
            validator: defaultCappedAssessmentBaselineValidator(),
            clock: clock,
            journal: [],
            engine: defaultCappedAssessmentBaselineEngine(flags)
        )
    }
}
