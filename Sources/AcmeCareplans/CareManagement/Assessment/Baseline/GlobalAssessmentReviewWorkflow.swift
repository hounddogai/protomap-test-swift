import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves global assessment reviews through their life cycle and keeps a journal of what it did.
    final class GlobalAssessmentReviewCoordinator {
        var store: any GlobalAssessmentReviewStore
        var validator: GlobalAssessmentReviewValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any GlobalAssessmentReviewStore, validator: GlobalAssessmentReviewValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("global assessment review \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalAssessmentReviewStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global assessment review \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalAssessmentReviewStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
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

    static func newGlobalAssessmentReviewCoordinator(_ store: any GlobalAssessmentReviewStore, clock: any Kit.Clocks.Clock) -> GlobalAssessmentReviewCoordinator {
        return GlobalAssessmentReviewCoordinator(
            store: store,
            validator: defaultGlobalAssessmentReviewValidator(),
            clock: clock,
            journal: []
        )
    }
}
