import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves manual care gap metrics through their life cycle and keeps a journal of what it did.
    final class ManualCareGapMetricCoordinator {
        var store: any ManualCareGapMetricStore
        var validator: ManualCareGapMetricValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ManualCareGapMetricEngine

        init(store: any ManualCareGapMetricStore, validator: ManualCareGapMetricValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ManualCareGapMetricEngine) {
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
                throw Kit.Failure("manual care gap metric \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualCareGapMetricStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual care gap metric \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualCareGapMetricStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual care gap metric \(code) not found")
            }
            let result = engine.price(item)
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

    static func newManualCareGapMetricCoordinator(_ store: any ManualCareGapMetricStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ManualCareGapMetricCoordinator {
        return ManualCareGapMetricCoordinator(
            store: store,
            validator: defaultManualCareGapMetricValidator(),
            clock: clock,
            journal: [],
            engine: defaultManualCareGapMetricEngine(flags)
        )
    }
}
