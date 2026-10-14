import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves legacy isolation metrics through their life cycle and keeps a journal of what it did.
    final class LegacyIsolationMetricManager {
        var store: any LegacyIsolationMetricStore
        var validator: LegacyIsolationMetricValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LegacyIsolationMetricEngine

        init(store: any LegacyIsolationMetricStore, validator: LegacyIsolationMetricValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LegacyIsolationMetricEngine) {
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
                throw Kit.Failure("legacy isolation metric \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyIsolationMetricStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy isolation metric \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyIsolationMetricStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy isolation metric \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newLegacyIsolationMetricManager(_ store: any LegacyIsolationMetricStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> LegacyIsolationMetricManager {
        return LegacyIsolationMetricManager(
            store: store,
            validator: defaultLegacyIsolationMetricValidator(),
            clock: clock,
            journal: [],
            engine: defaultLegacyIsolationMetricEngine(flags)
        )
    }
}
