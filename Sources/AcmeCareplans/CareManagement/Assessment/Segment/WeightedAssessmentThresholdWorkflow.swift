import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves weighted assessment thresholds through their life cycle and keeps a journal of what it did.
    final class WeightedAssessmentThresholdManager {
        var store: any WeightedAssessmentThresholdStore
        var validator: WeightedAssessmentThresholdValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any WeightedAssessmentThresholdStore, validator: WeightedAssessmentThresholdValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted assessment threshold \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedAssessmentThresholdStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted assessment threshold \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedAssessmentThresholdStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
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

    static func newWeightedAssessmentThresholdManager(_ store: any WeightedAssessmentThresholdStore, clock: any Kit.Clocks.Clock) -> WeightedAssessmentThresholdManager {
        return WeightedAssessmentThresholdManager(
            store: store,
            validator: defaultWeightedAssessmentThresholdValidator(),
            clock: clock,
            journal: []
        )
    }
}
