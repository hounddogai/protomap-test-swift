import AcmePlatform
import Foundation

extension Consent {
    /// Moves proxy batches through their life cycle and keeps a journal of what it did.
    final class ProxyBatchCoordinator {
        var store: any ProxyBatchStore
        var validator: ProxyBatchValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ProxyBatchStore, validator: ProxyBatchValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("proxy batch \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ProxyBatchStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("proxy batch \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ProxyBatchStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
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

    static func newProxyBatchCoordinator(_ store: any ProxyBatchStore, clock: any Kit.Clocks.Clock) -> ProxyBatchCoordinator {
        return ProxyBatchCoordinator(
            store: store,
            validator: defaultProxyBatchValidator(),
            clock: clock,
            journal: []
        )
    }
}
