import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves assessment quotas through their life cycle and keeps a journal of what it did.
    final class AssessmentQuotaCoordinator {
        var store: any AssessmentQuotaStore
        var validator: AssessmentQuotaValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any AssessmentQuotaStore, validator: AssessmentQuotaValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("assessment quota \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AssessmentQuotaStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("assessment quota \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AssessmentQuotaStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newAssessmentQuotaCoordinator(_ store: any AssessmentQuotaStore, clock: any Kit.Clocks.Clock) -> AssessmentQuotaCoordinator {
        return AssessmentQuotaCoordinator(
            store: store,
            validator: defaultAssessmentQuotaValidator(),
            clock: clock,
            journal: []
        )
    }
}
