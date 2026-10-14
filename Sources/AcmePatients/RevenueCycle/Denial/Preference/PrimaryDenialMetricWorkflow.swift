import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves primary denial metrics through their life cycle and keeps a journal of what it did.
    final class PrimaryDenialMetricManager {
        var store: any PrimaryDenialMetricStore
        var validator: PrimaryDenialMetricValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrimaryDenialMetricEngine

        init(store: any PrimaryDenialMetricStore, validator: PrimaryDenialMetricValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrimaryDenialMetricEngine) {
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
                throw Kit.Failure("primary denial metric \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryDenialMetricStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary denial metric \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryDenialMetricStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary denial metric \(code) not found")
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

    static func newPrimaryDenialMetricManager(_ store: any PrimaryDenialMetricStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PrimaryDenialMetricManager {
        return PrimaryDenialMetricManager(
            store: store,
            validator: defaultPrimaryDenialMetricValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrimaryDenialMetricEngine(flags)
        )
    }
}
