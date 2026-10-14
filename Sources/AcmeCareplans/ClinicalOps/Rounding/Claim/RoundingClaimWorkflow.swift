import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves rounding claims through their life cycle and keeps a journal of what it did.
    final class RoundingClaimService {
        var store: any RoundingClaimStore
        var validator: RoundingClaimValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RoundingClaimEngine

        init(store: any RoundingClaimStore, validator: RoundingClaimValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RoundingClaimEngine) {
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
                throw Kit.Failure("rounding claim \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RoundingClaimStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rounding claim \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RoundingClaimStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("rounding claim \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newRoundingClaimService(_ store: any RoundingClaimStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RoundingClaimService {
        return RoundingClaimService(
            store: store,
            validator: defaultRoundingClaimValidator(),
            clock: clock,
            journal: [],
            engine: defaultRoundingClaimEngine(flags)
        )
    }
}
