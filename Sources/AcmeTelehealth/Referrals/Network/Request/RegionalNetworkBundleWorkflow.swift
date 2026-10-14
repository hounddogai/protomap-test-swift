import AcmePlatform
import Foundation

extension Referrals {
    /// Moves regional network bundles through their life cycle and keeps a journal of what it did.
    final class RegionalNetworkBundleCoordinator {
        var store: any RegionalNetworkBundleStore
        var validator: RegionalNetworkBundleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RegionalNetworkBundleEngine

        init(store: any RegionalNetworkBundleStore, validator: RegionalNetworkBundleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RegionalNetworkBundleEngine) {
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
                throw Kit.Failure("regional network bundle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalNetworkBundleStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional network bundle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalNetworkBundleStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional network bundle \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newRegionalNetworkBundleCoordinator(_ store: any RegionalNetworkBundleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RegionalNetworkBundleCoordinator {
        return RegionalNetworkBundleCoordinator(
            store: store,
            validator: defaultRegionalNetworkBundleValidator(),
            clock: clock,
            journal: [],
            engine: defaultRegionalNetworkBundleEngine(flags)
        )
    }
}
