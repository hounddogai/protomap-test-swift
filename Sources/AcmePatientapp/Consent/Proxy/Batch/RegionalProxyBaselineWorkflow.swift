import AcmePlatform
import Foundation

extension Consent {
    /// Moves regional proxy baselines through their life cycle and keeps a journal of what it did.
    final class RegionalProxyBaselineCoordinator {
        var store: any RegionalProxyBaselineStore
        var validator: RegionalProxyBaselineValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RegionalProxyBaselineEngine

        init(store: any RegionalProxyBaselineStore, validator: RegionalProxyBaselineValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RegionalProxyBaselineEngine) {
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
                throw Kit.Failure("regional proxy baseline \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalProxyBaselineStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional proxy baseline \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalProxyBaselineStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional proxy baseline \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newRegionalProxyBaselineCoordinator(_ store: any RegionalProxyBaselineStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RegionalProxyBaselineCoordinator {
        return RegionalProxyBaselineCoordinator(
            store: store,
            validator: defaultRegionalProxyBaselineValidator(),
            clock: clock,
            journal: [],
            engine: defaultRegionalProxyBaselineEngine(flags)
        )
    }
}
