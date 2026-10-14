import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves strict alert checkpoints through their life cycle and keeps a journal of what it did.
    final class StrictAlertCheckpointCoordinator {
        var store: any StrictAlertCheckpointStore
        var validator: StrictAlertCheckpointValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: StrictAlertCheckpointEngine

        init(store: any StrictAlertCheckpointStore, validator: StrictAlertCheckpointValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: StrictAlertCheckpointEngine) {
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
                throw Kit.Failure("strict alert checkpoint \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictAlertCheckpointStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict alert checkpoint \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictAlertCheckpointStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict alert checkpoint \(code) not found")
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

    static func newStrictAlertCheckpointCoordinator(_ store: any StrictAlertCheckpointStore, clock: any Kit.Clocks.Clock) -> StrictAlertCheckpointCoordinator {
        return StrictAlertCheckpointCoordinator(
            store: store,
            validator: defaultStrictAlertCheckpointValidator(),
            clock: clock,
            journal: [],
            engine: defaultStrictAlertCheckpointEngine()
        )
    }
}
