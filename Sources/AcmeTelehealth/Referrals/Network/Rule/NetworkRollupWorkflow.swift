import AcmePlatform
import Foundation

extension Referrals {
    /// Moves network rollups through their life cycle and keeps a journal of what it did.
    final class NetworkRollupCoordinator {
        var store: any NetworkRollupStore
        var validator: NetworkRollupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any NetworkRollupStore, validator: NetworkRollupValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("network rollup \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(NetworkRollupStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("network rollup \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(NetworkRollupStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newNetworkRollupCoordinator(_ store: any NetworkRollupStore, clock: any Kit.Clocks.Clock) -> NetworkRollupCoordinator {
        return NetworkRollupCoordinator(
            store: store,
            validator: defaultNetworkRollupValidator(),
            clock: clock,
            journal: []
        )
    }
}
