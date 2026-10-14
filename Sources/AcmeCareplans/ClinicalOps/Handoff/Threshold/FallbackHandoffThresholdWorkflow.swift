import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves fallback handoff thresholds through their life cycle and keeps a journal of what it did.
    final class FallbackHandoffThresholdCoordinator {
        var store: any FallbackHandoffThresholdStore
        var validator: FallbackHandoffThresholdValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FallbackHandoffThresholdEngine

        init(store: any FallbackHandoffThresholdStore, validator: FallbackHandoffThresholdValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FallbackHandoffThresholdEngine) {
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
                throw Kit.Failure("fallback handoff threshold \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackHandoffThresholdStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback handoff threshold \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackHandoffThresholdStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback handoff threshold \(code) not found")
            }
            let result = engine.run(item)
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

    static func newFallbackHandoffThresholdCoordinator(_ store: any FallbackHandoffThresholdStore, clock: any Kit.Clocks.Clock) -> FallbackHandoffThresholdCoordinator {
        return FallbackHandoffThresholdCoordinator(
            store: store,
            validator: defaultFallbackHandoffThresholdValidator(),
            clock: clock,
            journal: [],
            engine: defaultFallbackHandoffThresholdEngine()
        )
    }
}
