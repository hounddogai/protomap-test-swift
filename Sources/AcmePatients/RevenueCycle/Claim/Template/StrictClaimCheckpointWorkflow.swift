import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves strict claim checkpoints through their life cycle and keeps a journal of what it did.
    final class StrictClaimCheckpointService {
        var store: any StrictClaimCheckpointStore
        var validator: StrictClaimCheckpointValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: StrictClaimCheckpointEngine

        init(store: any StrictClaimCheckpointStore, validator: StrictClaimCheckpointValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: StrictClaimCheckpointEngine) {
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
                throw Kit.Failure("strict claim checkpoint \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictClaimCheckpointStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict claim checkpoint \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictClaimCheckpointStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict claim checkpoint \(code) not found")
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
                if item.endsAt > cutoff {
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

    static func newStrictClaimCheckpointService(_ store: any StrictClaimCheckpointStore, clock: any Kit.Clocks.Clock) -> StrictClaimCheckpointService {
        return StrictClaimCheckpointService(
            store: store,
            validator: defaultStrictClaimCheckpointValidator(),
            clock: clock,
            journal: [],
            engine: defaultStrictClaimCheckpointEngine()
        )
    }
}
