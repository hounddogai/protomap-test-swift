import AcmePlatform
import Foundation

extension Staffing {
    /// Moves fallback float pool checkpoints through their life cycle and keeps a journal of what it did.
    final class FallbackFloatPoolCheckpointWorkflow {
        var store: any FallbackFloatPoolCheckpointStore
        var validator: FallbackFloatPoolCheckpointValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FallbackFloatPoolCheckpointEngine

        init(store: any FallbackFloatPoolCheckpointStore, validator: FallbackFloatPoolCheckpointValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FallbackFloatPoolCheckpointEngine) {
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
                throw Kit.Failure("fallback float pool checkpoint \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackFloatPoolCheckpointStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback float pool checkpoint \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackFloatPoolCheckpointStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback float pool checkpoint \(code) not found")
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

    static func newFallbackFloatPoolCheckpointWorkflow(_ store: any FallbackFloatPoolCheckpointStore, clock: any Kit.Clocks.Clock) -> FallbackFloatPoolCheckpointWorkflow {
        return FallbackFloatPoolCheckpointWorkflow(
            store: store,
            validator: defaultFallbackFloatPoolCheckpointValidator(),
            clock: clock,
            journal: [],
            engine: defaultFallbackFloatPoolCheckpointEngine()
        )
    }
}
