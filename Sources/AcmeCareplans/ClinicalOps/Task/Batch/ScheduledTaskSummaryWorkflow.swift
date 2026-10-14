import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves scheduled task summaries through their life cycle and keeps a journal of what it did.
    final class ScheduledTaskSummaryService {
        var store: any ScheduledTaskSummaryStore
        var validator: ScheduledTaskSummaryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ScheduledTaskSummaryEngine

        init(store: any ScheduledTaskSummaryStore, validator: ScheduledTaskSummaryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ScheduledTaskSummaryEngine) {
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
                throw Kit.Failure("scheduled task summary \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledTaskSummaryStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled task summary \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledTaskSummaryStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled task summary \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newScheduledTaskSummaryService(_ store: any ScheduledTaskSummaryStore, clock: any Kit.Clocks.Clock) -> ScheduledTaskSummaryService {
        return ScheduledTaskSummaryService(
            store: store,
            validator: defaultScheduledTaskSummaryValidator(),
            clock: clock,
            journal: [],
            engine: defaultScheduledTaskSummaryEngine()
        )
    }
}
