import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves fallback risk score checkpoints through their life cycle and keeps a journal of what it did.
    final class FallbackRiskScoreCheckpointWorkflow {
        var store: any FallbackRiskScoreCheckpointStore
        var validator: FallbackRiskScoreCheckpointValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FallbackRiskScoreCheckpointEngine

        init(store: any FallbackRiskScoreCheckpointStore, validator: FallbackRiskScoreCheckpointValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FallbackRiskScoreCheckpointEngine) {
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
                throw Kit.Failure("fallback risk score checkpoint \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackRiskScoreCheckpointStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback risk score checkpoint \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackRiskScoreCheckpointStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback risk score checkpoint \(code) not found")
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

    static func newFallbackRiskScoreCheckpointWorkflow(_ store: any FallbackRiskScoreCheckpointStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> FallbackRiskScoreCheckpointWorkflow {
        return FallbackRiskScoreCheckpointWorkflow(
            store: store,
            validator: defaultFallbackRiskScoreCheckpointValidator(),
            clock: clock,
            journal: [],
            engine: defaultFallbackRiskScoreCheckpointEngine(flags)
        )
    }
}
