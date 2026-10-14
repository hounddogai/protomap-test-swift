import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves batched care gap digests through their life cycle and keeps a journal of what it did.
    final class BatchedCareGapDigestManager {
        var store: any BatchedCareGapDigestStore
        var validator: BatchedCareGapDigestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any BatchedCareGapDigestStore, validator: BatchedCareGapDigestValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("batched care gap digest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedCareGapDigestStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched care gap digest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedCareGapDigestStatus.retired)
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

    static func newBatchedCareGapDigestManager(_ store: any BatchedCareGapDigestStore, clock: any Kit.Clocks.Clock) -> BatchedCareGapDigestManager {
        return BatchedCareGapDigestManager(
            store: store,
            validator: defaultBatchedCareGapDigestValidator(),
            clock: clock,
            journal: []
        )
    }
}
