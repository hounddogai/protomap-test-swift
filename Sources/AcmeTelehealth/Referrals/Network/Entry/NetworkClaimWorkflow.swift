import AcmePlatform
import Foundation

extension Referrals {
    /// Moves network claims through their life cycle and keeps a journal of what it did.
    final class NetworkClaimWorkflow {
        var store: any NetworkClaimStore
        var validator: NetworkClaimValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any NetworkClaimStore, validator: NetworkClaimValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("network claim \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(NetworkClaimStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("network claim \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(NetworkClaimStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
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

    static func newNetworkClaimWorkflow(_ store: any NetworkClaimStore, clock: any Kit.Clocks.Clock) -> NetworkClaimWorkflow {
        return NetworkClaimWorkflow(
            store: store,
            validator: defaultNetworkClaimValidator(),
            clock: clock,
            journal: []
        )
    }
}
