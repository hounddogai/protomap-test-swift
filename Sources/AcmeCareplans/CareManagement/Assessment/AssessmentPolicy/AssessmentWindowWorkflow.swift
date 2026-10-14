import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves assessment windows through their life cycle and keeps a journal of what it did.
    final class AssessmentWindowCoordinator {
        var store: any AssessmentWindowStore
        var validator: AssessmentWindowValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AssessmentWindowEngine

        init(store: any AssessmentWindowStore, validator: AssessmentWindowValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AssessmentWindowEngine) {
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
                throw Kit.Failure("assessment window \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AssessmentWindowStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("assessment window \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AssessmentWindowStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("assessment window \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newAssessmentWindowCoordinator(_ store: any AssessmentWindowStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> AssessmentWindowCoordinator {
        return AssessmentWindowCoordinator(
            store: store,
            validator: defaultAssessmentWindowValidator(),
            clock: clock,
            journal: [],
            engine: defaultAssessmentWindowEngine(flags)
        )
    }
}
