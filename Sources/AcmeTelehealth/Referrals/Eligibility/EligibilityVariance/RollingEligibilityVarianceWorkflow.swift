import AcmePlatform
import Foundation

extension Referrals {
    /// Moves rolling eligibility variances through their life cycle and keeps a journal of what it did.
    final class RollingEligibilityVarianceService {
        var store: any RollingEligibilityVarianceStore
        var validator: RollingEligibilityVarianceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RollingEligibilityVarianceEngine

        init(store: any RollingEligibilityVarianceStore, validator: RollingEligibilityVarianceValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RollingEligibilityVarianceEngine) {
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
                throw Kit.Failure("rolling eligibility variance \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingEligibilityVarianceStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling eligibility variance \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingEligibilityVarianceStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling eligibility variance \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newRollingEligibilityVarianceService(_ store: any RollingEligibilityVarianceStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RollingEligibilityVarianceService {
        return RollingEligibilityVarianceService(
            store: store,
            validator: defaultRollingEligibilityVarianceValidator(),
            clock: clock,
            journal: [],
            engine: defaultRollingEligibilityVarianceEngine(flags)
        )
    }
}
