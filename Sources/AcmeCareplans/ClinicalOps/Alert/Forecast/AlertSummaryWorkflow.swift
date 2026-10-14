import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves alert summaries through their life cycle and keeps a journal of what it did.
    final class AlertSummaryManager {
        var store: any AlertSummaryStore
        var validator: AlertSummaryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any AlertSummaryStore, validator: AlertSummaryValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("alert summary \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AlertSummaryStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("alert summary \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AlertSummaryStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newAlertSummaryManager(_ store: any AlertSummaryStore, clock: any Kit.Clocks.Clock) -> AlertSummaryManager {
        return AlertSummaryManager(
            store: store,
            validator: defaultAlertSummaryValidator(),
            clock: clock,
            journal: []
        )
    }
}
