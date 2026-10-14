import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves global alert summaries through their life cycle and keeps a journal of what it did.
    final class GlobalAlertSummaryManager {
        var store: any GlobalAlertSummaryStore
        var validator: GlobalAlertSummaryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any GlobalAlertSummaryStore, validator: GlobalAlertSummaryValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("global alert summary \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalAlertSummaryStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global alert summary \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalAlertSummaryStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
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

    static func newGlobalAlertSummaryManager(_ store: any GlobalAlertSummaryStore, clock: any Kit.Clocks.Clock) -> GlobalAlertSummaryManager {
        return GlobalAlertSummaryManager(
            store: store,
            validator: defaultGlobalAlertSummaryValidator(),
            clock: clock,
            journal: []
        )
    }
}
