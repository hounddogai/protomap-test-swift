import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves remittance snapshots through their life cycle and keeps a journal of what it did.
    final class RemittanceSnapshotService {
        var store: any RemittanceSnapshotStore
        var validator: RemittanceSnapshotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RemittanceSnapshotEngine

        init(store: any RemittanceSnapshotStore, validator: RemittanceSnapshotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RemittanceSnapshotEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("remittance snapshot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RemittanceSnapshotStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("remittance snapshot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RemittanceSnapshotStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("remittance snapshot \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newRemittanceSnapshotService(_ store: any RemittanceSnapshotStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RemittanceSnapshotService {
        return RemittanceSnapshotService(
            store: store,
            validator: defaultRemittanceSnapshotValidator(),
            clock: clock,
            journal: [],
            engine: defaultRemittanceSnapshotEngine(flags)
        )
    }
}
