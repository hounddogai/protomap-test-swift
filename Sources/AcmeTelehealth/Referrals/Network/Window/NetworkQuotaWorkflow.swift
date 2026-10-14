import AcmePlatform
import Foundation

extension Referrals {
    /// Moves network quotas through their life cycle and keeps a journal of what it did.
    final class NetworkQuotaWorkflow {
        var store: any NetworkQuotaStore
        var validator: NetworkQuotaValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any NetworkQuotaStore, validator: NetworkQuotaValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("network quota \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(NetworkQuotaStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("network quota \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(NetworkQuotaStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
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

    static func newNetworkQuotaWorkflow(_ store: any NetworkQuotaStore, clock: any Kit.Clocks.Clock) -> NetworkQuotaWorkflow {
        return NetworkQuotaWorkflow(
            store: store,
            validator: defaultNetworkQuotaValidator(),
            clock: clock,
            journal: []
        )
    }
}
