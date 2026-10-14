import AcmePlatform
import Foundation

extension Referrals {
    /// Moves tiered network digests through their life cycle and keeps a journal of what it did.
    final class TieredNetworkDigestCoordinator {
        var store: any TieredNetworkDigestStore
        var validator: TieredNetworkDigestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TieredNetworkDigestEngine

        init(store: any TieredNetworkDigestStore, validator: TieredNetworkDigestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TieredNetworkDigestEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered network digest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredNetworkDigestStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered network digest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredNetworkDigestStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered network digest \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newTieredNetworkDigestCoordinator(_ store: any TieredNetworkDigestStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> TieredNetworkDigestCoordinator {
        return TieredNetworkDigestCoordinator(
            store: store,
            validator: defaultTieredNetworkDigestValidator(),
            clock: clock,
            journal: [],
            engine: defaultTieredNetworkDigestEngine(flags)
        )
    }
}
