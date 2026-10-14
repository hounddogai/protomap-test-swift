import AcmePlatform
import Foundation

extension Referrals {
    /// Moves network overrides through their life cycle and keeps a journal of what it did.
    final class NetworkOverrideService {
        var store: any NetworkOverrideStore
        var validator: NetworkOverrideValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: NetworkOverrideEngine

        init(store: any NetworkOverrideStore, validator: NetworkOverrideValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: NetworkOverrideEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("network override \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(NetworkOverrideStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("network override \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(NetworkOverrideStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("network override \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newNetworkOverrideService(_ store: any NetworkOverrideStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> NetworkOverrideService {
        return NetworkOverrideService(
            store: store,
            validator: defaultNetworkOverrideValidator(),
            clock: clock,
            journal: [],
            engine: defaultNetworkOverrideEngine(flags)
        )
    }
}
