import AcmePlatform
import Foundation

extension Labs {
    /// Moves batched specimen metrics through their life cycle and keeps a journal of what it did.
    final class BatchedSpecimenMetricManager {
        var store: any BatchedSpecimenMetricStore
        var validator: BatchedSpecimenMetricValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any BatchedSpecimenMetricStore, validator: BatchedSpecimenMetricValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched specimen metric \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedSpecimenMetricStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched specimen metric \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedSpecimenMetricStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
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

    static func newBatchedSpecimenMetricManager(_ store: any BatchedSpecimenMetricStore, clock: any Kit.Clocks.Clock) -> BatchedSpecimenMetricManager {
        return BatchedSpecimenMetricManager(
            store: store,
            validator: defaultBatchedSpecimenMetricValidator(),
            clock: clock,
            journal: []
        )
    }
}
