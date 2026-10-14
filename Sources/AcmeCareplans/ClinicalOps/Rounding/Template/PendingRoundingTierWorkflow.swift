import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves pending rounding tiers through their life cycle and keeps a journal of what it did.
    final class PendingRoundingTierCoordinator {
        var store: any PendingRoundingTierStore
        var validator: PendingRoundingTierValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PendingRoundingTierEngine

        init(store: any PendingRoundingTierStore, validator: PendingRoundingTierValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PendingRoundingTierEngine) {
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
                throw Kit.Failure("pending rounding tier \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingRoundingTierStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending rounding tier \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingRoundingTierStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending rounding tier \(code) not found")
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

    static func newPendingRoundingTierCoordinator(_ store: any PendingRoundingTierStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PendingRoundingTierCoordinator {
        return PendingRoundingTierCoordinator(
            store: store,
            validator: defaultPendingRoundingTierValidator(),
            clock: clock,
            journal: [],
            engine: defaultPendingRoundingTierEngine(flags)
        )
    }
}
