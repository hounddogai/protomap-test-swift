import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves scheduled alert summaries through their life cycle and keeps a journal of what it did.
    final class ScheduledAlertSummaryManager {
        var store: any ScheduledAlertSummaryStore
        var validator: ScheduledAlertSummaryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ScheduledAlertSummaryStore, validator: ScheduledAlertSummaryValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("scheduled alert summary \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledAlertSummaryStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled alert summary \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledAlertSummaryStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
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

    static func newScheduledAlertSummaryManager(_ store: any ScheduledAlertSummaryStore, clock: any Kit.Clocks.Clock) -> ScheduledAlertSummaryManager {
        return ScheduledAlertSummaryManager(
            store: store,
            validator: defaultScheduledAlertSummaryValidator(),
            clock: clock,
            journal: []
        )
    }
}
