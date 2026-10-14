import AcmePlatform
import Foundation

extension Consent {
    /// Moves manual proxy metrics through their life cycle and keeps a journal of what it did.
    final class ManualProxyMetricWorkflow {
        var store: any ManualProxyMetricStore
        var validator: ManualProxyMetricValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ManualProxyMetricEngine

        init(store: any ManualProxyMetricStore, validator: ManualProxyMetricValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ManualProxyMetricEngine) {
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
                throw Kit.Failure("manual proxy metric \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualProxyMetricStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual proxy metric \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualProxyMetricStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual proxy metric \(code) not found")
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
                if item.createdAt > cutoff {
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

    static func newManualProxyMetricWorkflow(_ store: any ManualProxyMetricStore, clock: any Kit.Clocks.Clock) -> ManualProxyMetricWorkflow {
        return ManualProxyMetricWorkflow(
            store: store,
            validator: defaultManualProxyMetricValidator(),
            clock: clock,
            journal: [],
            engine: defaultManualProxyMetricEngine()
        )
    }
}
