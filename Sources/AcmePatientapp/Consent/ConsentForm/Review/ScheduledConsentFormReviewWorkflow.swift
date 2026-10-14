import AcmePlatform
import Foundation

extension Consent {
    /// Moves scheduled consent form reviews through their life cycle and keeps a journal of what it did.
    final class ScheduledConsentFormReviewCoordinator {
        var store: any ScheduledConsentFormReviewStore
        var validator: ScheduledConsentFormReviewValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ScheduledConsentFormReviewEngine

        init(store: any ScheduledConsentFormReviewStore, validator: ScheduledConsentFormReviewValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ScheduledConsentFormReviewEngine) {
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
                throw Kit.Failure("scheduled consent form review \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledConsentFormReviewStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled consent form review \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledConsentFormReviewStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled consent form review \(code) not found")
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

    static func newScheduledConsentFormReviewCoordinator(_ store: any ScheduledConsentFormReviewStore, clock: any Kit.Clocks.Clock) -> ScheduledConsentFormReviewCoordinator {
        return ScheduledConsentFormReviewCoordinator(
            store: store,
            validator: defaultScheduledConsentFormReviewValidator(),
            clock: clock,
            journal: [],
            engine: defaultScheduledConsentFormReviewEngine()
        )
    }
}
