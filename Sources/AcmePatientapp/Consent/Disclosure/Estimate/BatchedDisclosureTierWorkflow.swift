import AcmePlatform
import Foundation

extension Consent {
    /// Moves batched disclosure tiers through their life cycle and keeps a journal of what it did.
    final class BatchedDisclosureTierService {
        var store: any BatchedDisclosureTierStore
        var validator: BatchedDisclosureTierValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any BatchedDisclosureTierStore, validator: BatchedDisclosureTierValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("batched disclosure tier \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedDisclosureTierStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched disclosure tier \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedDisclosureTierStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newBatchedDisclosureTierService(_ store: any BatchedDisclosureTierStore, clock: any Kit.Clocks.Clock) -> BatchedDisclosureTierService {
        return BatchedDisclosureTierService(
            store: store,
            validator: defaultBatchedDisclosureTierValidator(),
            clock: clock,
            journal: []
        )
    }
}
