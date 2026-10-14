import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves adaptive assessment assignments through their life cycle and keeps a journal of what it did.
    final class AdaptiveAssessmentAssignmentService {
        var store: any AdaptiveAssessmentAssignmentStore
        var validator: AdaptiveAssessmentAssignmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AdaptiveAssessmentAssignmentEngine

        init(store: any AdaptiveAssessmentAssignmentStore, validator: AdaptiveAssessmentAssignmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AdaptiveAssessmentAssignmentEngine) {
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
                throw Kit.Failure("adaptive assessment assignment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptiveAssessmentAssignmentStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive assessment assignment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptiveAssessmentAssignmentStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive assessment assignment \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newAdaptiveAssessmentAssignmentService(_ store: any AdaptiveAssessmentAssignmentStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> AdaptiveAssessmentAssignmentService {
        return AdaptiveAssessmentAssignmentService(
            store: store,
            validator: defaultAdaptiveAssessmentAssignmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultAdaptiveAssessmentAssignmentEngine(flags)
        )
    }
}
