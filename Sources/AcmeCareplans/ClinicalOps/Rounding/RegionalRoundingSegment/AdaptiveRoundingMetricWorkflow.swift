import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves adaptive rounding metrics through their life cycle and keeps a journal of what it did.
    final class AdaptiveRoundingMetricDesk {
        var store: any AdaptiveRoundingMetricStore
        var validator: AdaptiveRoundingMetricValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AdaptiveRoundingMetricEngine

        init(store: any AdaptiveRoundingMetricStore, validator: AdaptiveRoundingMetricValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AdaptiveRoundingMetricEngine) {
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
                throw Kit.Failure("adaptive rounding metric \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptiveRoundingMetricStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive rounding metric \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptiveRoundingMetricStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive rounding metric \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newAdaptiveRoundingMetricDesk(_ store: any AdaptiveRoundingMetricStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> AdaptiveRoundingMetricDesk {
        return AdaptiveRoundingMetricDesk(
            store: store,
            validator: defaultAdaptiveRoundingMetricValidator(),
            clock: clock,
            journal: [],
            engine: defaultAdaptiveRoundingMetricEngine(flags)
        )
    }
}
