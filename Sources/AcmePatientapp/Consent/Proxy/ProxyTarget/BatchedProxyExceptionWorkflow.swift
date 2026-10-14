import AcmePlatform
import Foundation

extension Consent {
    /// Moves batched proxy exceptions through their life cycle and keeps a journal of what it did.
    final class BatchedProxyExceptionService {
        var store: any BatchedProxyExceptionStore
        var validator: BatchedProxyExceptionValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any BatchedProxyExceptionStore, validator: BatchedProxyExceptionValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("batched proxy exception \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedProxyExceptionStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched proxy exception \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedProxyExceptionStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
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

    static func newBatchedProxyExceptionService(_ store: any BatchedProxyExceptionStore, clock: any Kit.Clocks.Clock) -> BatchedProxyExceptionService {
        return BatchedProxyExceptionService(
            store: store,
            validator: defaultBatchedProxyExceptionValidator(),
            clock: clock,
            journal: []
        )
    }
}
