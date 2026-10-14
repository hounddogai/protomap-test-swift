import AcmePlatform
import Foundation

extension Consent {
    /// Moves batched disclosure segments through their life cycle and keeps a journal of what it did.
    final class BatchedDisclosureSegmentService {
        var store: any BatchedDisclosureSegmentStore
        var validator: BatchedDisclosureSegmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any BatchedDisclosureSegmentStore, validator: BatchedDisclosureSegmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("batched disclosure segment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedDisclosureSegmentStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched disclosure segment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedDisclosureSegmentStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
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

    static func newBatchedDisclosureSegmentService(_ store: any BatchedDisclosureSegmentStore, clock: any Kit.Clocks.Clock) -> BatchedDisclosureSegmentService {
        return BatchedDisclosureSegmentService(
            store: store,
            validator: defaultBatchedDisclosureSegmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
