import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves recall metrics through their life cycle and keeps a journal of what it did.
    final class RecallMetricWorkflow {
        var store: any RecallMetricStore
        var validator: RecallMetricValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RecallMetricStore, validator: RecallMetricValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("recall metric \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RecallMetricStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("recall metric \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RecallMetricStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
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

    static func newRecallMetricWorkflow(_ store: any RecallMetricStore, clock: any Kit.Clocks.Clock) -> RecallMetricWorkflow {
        return RecallMetricWorkflow(
            store: store,
            validator: defaultRecallMetricValidator(),
            clock: clock,
            journal: []
        )
    }
}
