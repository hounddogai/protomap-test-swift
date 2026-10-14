import AcmePlatform
import Foundation

extension Referrals {
    /// Moves pending network bundles through their life cycle and keeps a journal of what it did.
    final class PendingNetworkBundleDesk {
        var store: any PendingNetworkBundleStore
        var validator: PendingNetworkBundleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PendingNetworkBundleStore, validator: PendingNetworkBundleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("pending network bundle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingNetworkBundleStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending network bundle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingNetworkBundleStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
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

    static func newPendingNetworkBundleDesk(_ store: any PendingNetworkBundleStore, clock: any Kit.Clocks.Clock) -> PendingNetworkBundleDesk {
        return PendingNetworkBundleDesk(
            store: store,
            validator: defaultPendingNetworkBundleValidator(),
            clock: clock,
            journal: []
        )
    }
}
