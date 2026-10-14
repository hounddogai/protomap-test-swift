import AcmePlatform
import Foundation

extension Referrals {
    /// Moves network tiers through their life cycle and keeps a journal of what it did.
    final class NetworkTierCoordinator {
        var store: any NetworkTierStore
        var validator: NetworkTierValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: NetworkTierEngine

        init(store: any NetworkTierStore, validator: NetworkTierValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: NetworkTierEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("network tier \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(NetworkTierStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("network tier \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(NetworkTierStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("network tier \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newNetworkTierCoordinator(_ store: any NetworkTierStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> NetworkTierCoordinator {
        return NetworkTierCoordinator(
            store: store,
            validator: defaultNetworkTierValidator(),
            clock: clock,
            journal: [],
            engine: defaultNetworkTierEngine(flags)
        )
    }
}
