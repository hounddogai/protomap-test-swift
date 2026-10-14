import AcmePlatform
import Foundation

extension Referrals {
    /// Moves scheduled network bundles through their life cycle and keeps a journal of what it did.
    final class ScheduledNetworkBundleCoordinator {
        var store: any ScheduledNetworkBundleStore
        var validator: ScheduledNetworkBundleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ScheduledNetworkBundleEngine

        init(store: any ScheduledNetworkBundleStore, validator: ScheduledNetworkBundleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ScheduledNetworkBundleEngine) {
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
                throw Kit.Failure("scheduled network bundle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledNetworkBundleStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled network bundle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledNetworkBundleStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled network bundle \(code) not found")
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

    static func newScheduledNetworkBundleCoordinator(_ store: any ScheduledNetworkBundleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ScheduledNetworkBundleCoordinator {
        return ScheduledNetworkBundleCoordinator(
            store: store,
            validator: defaultScheduledNetworkBundleValidator(),
            clock: clock,
            journal: [],
            engine: defaultScheduledNetworkBundleEngine(flags)
        )
    }
}
