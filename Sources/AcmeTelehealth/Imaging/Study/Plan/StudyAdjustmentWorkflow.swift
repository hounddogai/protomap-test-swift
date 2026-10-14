import AcmePlatform
import Foundation

extension Imaging {
    /// Moves study adjustments through their life cycle and keeps a journal of what it did.
    final class StudyAdjustmentManager {
        var store: any StudyAdjustmentStore
        var validator: StudyAdjustmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: StudyAdjustmentEngine

        init(store: any StudyAdjustmentStore, validator: StudyAdjustmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: StudyAdjustmentEngine) {
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
                throw Kit.Failure("study adjustment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StudyAdjustmentStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("study adjustment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StudyAdjustmentStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("study adjustment \(code) not found")
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

    static func newStudyAdjustmentManager(_ store: any StudyAdjustmentStore, clock: any Kit.Clocks.Clock) -> StudyAdjustmentManager {
        return StudyAdjustmentManager(
            store: store,
            validator: defaultStudyAdjustmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultStudyAdjustmentEngine()
        )
    }
}
