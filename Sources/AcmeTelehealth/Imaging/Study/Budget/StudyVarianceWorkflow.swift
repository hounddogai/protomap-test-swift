import AcmePlatform
import Foundation

extension Imaging {
    /// Moves study variances through their life cycle and keeps a journal of what it did.
    final class StudyVarianceService {
        var store: any StudyVarianceStore
        var validator: StudyVarianceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: StudyVarianceEngine

        init(store: any StudyVarianceStore, validator: StudyVarianceValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: StudyVarianceEngine) {
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
                throw Kit.Failure("study variance \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StudyVarianceStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("study variance \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StudyVarianceStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("study variance \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newStudyVarianceService(_ store: any StudyVarianceStore, clock: any Kit.Clocks.Clock) -> StudyVarianceService {
        return StudyVarianceService(
            store: store,
            validator: defaultStudyVarianceValidator(),
            clock: clock,
            journal: [],
            engine: defaultStudyVarianceEngine()
        )
    }
}
