import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves assessment preferences through their life cycle and keeps a journal of what it did.
    final class AssessmentPreferenceManager {
        var store: any AssessmentPreferenceStore
        var validator: AssessmentPreferenceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AssessmentPreferenceEngine

        init(store: any AssessmentPreferenceStore, validator: AssessmentPreferenceValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AssessmentPreferenceEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("assessment preference \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AssessmentPreferenceStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("assessment preference \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AssessmentPreferenceStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("assessment preference \(code) not found")
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
                if item.startsAt > cutoff {
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

    static func newAssessmentPreferenceManager(_ store: any AssessmentPreferenceStore, clock: any Kit.Clocks.Clock) -> AssessmentPreferenceManager {
        return AssessmentPreferenceManager(
            store: store,
            validator: defaultAssessmentPreferenceValidator(),
            clock: clock,
            journal: [],
            engine: defaultAssessmentPreferenceEngine()
        )
    }
}
