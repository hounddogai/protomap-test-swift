import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves rounding estimates through their life cycle and keeps a journal of what it did.
    final class RoundingEstimateDesk {
        var store: any RoundingEstimateStore
        var validator: RoundingEstimateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RoundingEstimateEngine

        init(store: any RoundingEstimateStore, validator: RoundingEstimateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RoundingEstimateEngine) {
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
                throw Kit.Failure("rounding estimate \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RoundingEstimateStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rounding estimate \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RoundingEstimateStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("rounding estimate \(code) not found")
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
                if item.expiresAt > cutoff {
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

    static func newRoundingEstimateDesk(_ store: any RoundingEstimateStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RoundingEstimateDesk {
        return RoundingEstimateDesk(
            store: store,
            validator: defaultRoundingEstimateValidator(),
            clock: clock,
            journal: [],
            engine: defaultRoundingEstimateEngine(flags)
        )
    }
}
