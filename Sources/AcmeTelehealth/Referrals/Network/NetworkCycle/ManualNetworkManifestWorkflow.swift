import AcmePlatform
import Foundation

extension Referrals {
    /// Moves manual network manifests through their life cycle and keeps a journal of what it did.
    final class ManualNetworkManifestManager {
        var store: any ManualNetworkManifestStore
        var validator: ManualNetworkManifestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ManualNetworkManifestEngine

        init(store: any ManualNetworkManifestStore, validator: ManualNetworkManifestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ManualNetworkManifestEngine) {
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
                throw Kit.Failure("manual network manifest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualNetworkManifestStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual network manifest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualNetworkManifestStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual network manifest \(code) not found")
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

    static func newManualNetworkManifestManager(_ store: any ManualNetworkManifestStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ManualNetworkManifestManager {
        return ManualNetworkManifestManager(
            store: store,
            validator: defaultManualNetworkManifestValidator(),
            clock: clock,
            journal: [],
            engine: defaultManualNetworkManifestEngine(flags)
        )
    }
}
