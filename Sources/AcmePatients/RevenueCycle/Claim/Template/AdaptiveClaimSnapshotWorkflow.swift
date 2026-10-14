import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves adaptive claim snapshots through their life cycle and keeps a journal of what it did.
    final class AdaptiveClaimSnapshotCoordinator {
        var store: any AdaptiveClaimSnapshotStore
        var validator: AdaptiveClaimSnapshotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AdaptiveClaimSnapshotEngine

        init(store: any AdaptiveClaimSnapshotStore, validator: AdaptiveClaimSnapshotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AdaptiveClaimSnapshotEngine) {
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
                throw Kit.Failure("adaptive claim snapshot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptiveClaimSnapshotStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive claim snapshot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptiveClaimSnapshotStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive claim snapshot \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newAdaptiveClaimSnapshotCoordinator(_ store: any AdaptiveClaimSnapshotStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> AdaptiveClaimSnapshotCoordinator {
        return AdaptiveClaimSnapshotCoordinator(
            store: store,
            validator: defaultAdaptiveClaimSnapshotValidator(),
            clock: clock,
            journal: [],
            engine: defaultAdaptiveClaimSnapshotEngine(flags)
        )
    }
}
