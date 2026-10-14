import AcmePlatform
import Foundation

extension Consent {
    /// Moves proxy metrics through their life cycle and keeps a journal of what it did.
    final class ProxyMetricCoordinator {
        var store: any ProxyMetricStore
        var validator: ProxyMetricValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ProxyMetricEngine

        init(store: any ProxyMetricStore, validator: ProxyMetricValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ProxyMetricEngine) {
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
                throw Kit.Failure("proxy metric \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ProxyMetricStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("proxy metric \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ProxyMetricStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("proxy metric \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newProxyMetricCoordinator(_ store: any ProxyMetricStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ProxyMetricCoordinator {
        return ProxyMetricCoordinator(
            store: store,
            validator: defaultProxyMetricValidator(),
            clock: clock,
            journal: [],
            engine: defaultProxyMetricEngine(flags)
        )
    }
}
