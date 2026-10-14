import AcmePlatform
import Foundation

extension Labs {
    /// Moves regional accession checkpoints through their life cycle and keeps a journal of what it did.
    final class RegionalAccessionCheckpointCoordinator {
        var store: any RegionalAccessionCheckpointStore
        var validator: RegionalAccessionCheckpointValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RegionalAccessionCheckpointEngine

        init(store: any RegionalAccessionCheckpointStore, validator: RegionalAccessionCheckpointValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RegionalAccessionCheckpointEngine) {
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
                throw Kit.Failure("regional accession checkpoint \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalAccessionCheckpointStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional accession checkpoint \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalAccessionCheckpointStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional accession checkpoint \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newRegionalAccessionCheckpointCoordinator(_ store: any RegionalAccessionCheckpointStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RegionalAccessionCheckpointCoordinator {
        return RegionalAccessionCheckpointCoordinator(
            store: store,
            validator: defaultRegionalAccessionCheckpointValidator(),
            clock: clock,
            journal: [],
            engine: defaultRegionalAccessionCheckpointEngine(flags)
        )
    }
}
