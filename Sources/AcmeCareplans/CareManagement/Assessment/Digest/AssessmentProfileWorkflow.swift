import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves assessment profiles through their life cycle and keeps a journal of what it did.
    final class AssessmentProfileService {
        var store: any AssessmentProfileStore
        var validator: AssessmentProfileValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any AssessmentProfileStore, validator: AssessmentProfileValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("assessment profile \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AssessmentProfileStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("assessment profile \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AssessmentProfileStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
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

    static func newAssessmentProfileService(_ store: any AssessmentProfileStore, clock: any Kit.Clocks.Clock) -> AssessmentProfileService {
        return AssessmentProfileService(
            store: store,
            validator: defaultAssessmentProfileValidator(),
            clock: clock,
            journal: []
        )
    }
}
