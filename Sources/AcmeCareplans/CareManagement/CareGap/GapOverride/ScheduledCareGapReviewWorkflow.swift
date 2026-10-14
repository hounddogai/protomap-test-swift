import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves scheduled care gap reviews through their life cycle and keeps a journal of what it did.
    final class ScheduledCareGapReviewManager {
        var store: any ScheduledCareGapReviewStore
        var validator: ScheduledCareGapReviewValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ScheduledCareGapReviewStore, validator: ScheduledCareGapReviewValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("scheduled care gap review \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledCareGapReviewStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled care gap review \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledCareGapReviewStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
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

    static func newScheduledCareGapReviewManager(_ store: any ScheduledCareGapReviewStore, clock: any Kit.Clocks.Clock) -> ScheduledCareGapReviewManager {
        return ScheduledCareGapReviewManager(
            store: store,
            validator: defaultScheduledCareGapReviewValidator(),
            clock: clock,
            journal: []
        )
    }
}
