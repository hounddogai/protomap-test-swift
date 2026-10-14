import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves global census checkpoints through their life cycle and keeps a journal of what it did.
    final class GlobalCensusCheckpointCoordinator {
        var store: any GlobalCensusCheckpointStore
        var validator: GlobalCensusCheckpointValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GlobalCensusCheckpointEngine

        init(store: any GlobalCensusCheckpointStore, validator: GlobalCensusCheckpointValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GlobalCensusCheckpointEngine) {
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
                throw Kit.Failure("global census checkpoint \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalCensusCheckpointStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global census checkpoint \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalCensusCheckpointStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("global census checkpoint \(code) not found")
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

    static func newGlobalCensusCheckpointCoordinator(_ store: any GlobalCensusCheckpointStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> GlobalCensusCheckpointCoordinator {
        return GlobalCensusCheckpointCoordinator(
            store: store,
            validator: defaultGlobalCensusCheckpointValidator(),
            clock: clock,
            journal: [],
            engine: defaultGlobalCensusCheckpointEngine(flags)
        )
    }
}
