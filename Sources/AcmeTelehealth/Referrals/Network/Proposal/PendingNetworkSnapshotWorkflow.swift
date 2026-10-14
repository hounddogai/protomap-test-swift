import AcmePlatform
import Foundation

extension Referrals {
    /// Moves pending network snapshots through their life cycle and keeps a journal of what it did.
    final class PendingNetworkSnapshotCoordinator {
        var store: any PendingNetworkSnapshotStore
        var validator: PendingNetworkSnapshotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PendingNetworkSnapshotEngine

        init(store: any PendingNetworkSnapshotStore, validator: PendingNetworkSnapshotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PendingNetworkSnapshotEngine) {
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
                throw Kit.Failure("pending network snapshot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingNetworkSnapshotStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending network snapshot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingNetworkSnapshotStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending network snapshot \(code) not found")
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

    static func newPendingNetworkSnapshotCoordinator(_ store: any PendingNetworkSnapshotStore, clock: any Kit.Clocks.Clock) -> PendingNetworkSnapshotCoordinator {
        return PendingNetworkSnapshotCoordinator(
            store: store,
            validator: defaultPendingNetworkSnapshotValidator(),
            clock: clock,
            journal: [],
            engine: defaultPendingNetworkSnapshotEngine()
        )
    }
}
