import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves adaptive statement thresholds through their life cycle and keeps a journal of what it did.
    final class AdaptiveStatementThresholdManager {
        var store: any AdaptiveStatementThresholdStore
        var validator: AdaptiveStatementThresholdValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AdaptiveStatementThresholdEngine

        init(store: any AdaptiveStatementThresholdStore, validator: AdaptiveStatementThresholdValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AdaptiveStatementThresholdEngine) {
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
                throw Kit.Failure("adaptive statement threshold \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptiveStatementThresholdStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive statement threshold \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptiveStatementThresholdStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive statement threshold \(code) not found")
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

    static func newAdaptiveStatementThresholdManager(_ store: any AdaptiveStatementThresholdStore, clock: any Kit.Clocks.Clock) -> AdaptiveStatementThresholdManager {
        return AdaptiveStatementThresholdManager(
            store: store,
            validator: defaultAdaptiveStatementThresholdValidator(),
            clock: clock,
            journal: [],
            engine: defaultAdaptiveStatementThresholdEngine()
        )
    }
}
