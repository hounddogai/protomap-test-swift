import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves tiered rounding requests through their life cycle and keeps a journal of what it did.
    final class TieredRoundingRequestCoordinator {
        var store: any TieredRoundingRequestStore
        var validator: TieredRoundingRequestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TieredRoundingRequestEngine

        init(store: any TieredRoundingRequestStore, validator: TieredRoundingRequestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TieredRoundingRequestEngine) {
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
                throw Kit.Failure("tiered rounding request \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredRoundingRequestStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered rounding request \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredRoundingRequestStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered rounding request \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newTieredRoundingRequestCoordinator(_ store: any TieredRoundingRequestStore, clock: any Kit.Clocks.Clock) -> TieredRoundingRequestCoordinator {
        return TieredRoundingRequestCoordinator(
            store: store,
            validator: defaultTieredRoundingRequestValidator(),
            clock: clock,
            journal: [],
            engine: defaultTieredRoundingRequestEngine()
        )
    }
}
