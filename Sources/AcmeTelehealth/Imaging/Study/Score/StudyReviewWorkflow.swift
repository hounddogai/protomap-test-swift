import AcmePlatform
import Foundation

extension Imaging {
    /// Moves study reviews through their life cycle and keeps a journal of what it did.
    final class StudyReviewCoordinator {
        var store: any StudyReviewStore
        var validator: StudyReviewValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: StudyReviewEngine

        init(store: any StudyReviewStore, validator: StudyReviewValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: StudyReviewEngine) {
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
                throw Kit.Failure("study review \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StudyReviewStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("study review \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StudyReviewStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("study review \(code) not found")
            }
            let result = engine.run(item)
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

    static func newStudyReviewCoordinator(_ store: any StudyReviewStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> StudyReviewCoordinator {
        return StudyReviewCoordinator(
            store: store,
            validator: defaultStudyReviewValidator(),
            clock: clock,
            journal: [],
            engine: defaultStudyReviewEngine(flags)
        )
    }
}
