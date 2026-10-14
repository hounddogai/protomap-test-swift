import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves capped care protocol checkpoints through their life cycle and keeps a journal of what it did.
    final class CappedCareProtocolCheckpointCoordinator {
        var store: any CappedCareProtocolCheckpointStore
        var validator: CappedCareProtocolCheckpointValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CappedCareProtocolCheckpointEngine

        init(store: any CappedCareProtocolCheckpointStore, validator: CappedCareProtocolCheckpointValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CappedCareProtocolCheckpointEngine) {
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
                throw Kit.Failure("capped care protocol checkpoint \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedCareProtocolCheckpointStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped care protocol checkpoint \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedCareProtocolCheckpointStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped care protocol checkpoint \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newCappedCareProtocolCheckpointCoordinator(_ store: any CappedCareProtocolCheckpointStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CappedCareProtocolCheckpointCoordinator {
        return CappedCareProtocolCheckpointCoordinator(
            store: store,
            validator: defaultCappedCareProtocolCheckpointValidator(),
            clock: clock,
            journal: [],
            engine: defaultCappedCareProtocolCheckpointEngine(flags)
        )
    }
}
