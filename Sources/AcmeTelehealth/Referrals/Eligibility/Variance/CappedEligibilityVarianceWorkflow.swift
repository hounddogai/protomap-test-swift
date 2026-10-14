import AcmePlatform
import Foundation

extension Referrals {
    /// Moves capped eligibility variances through their life cycle and keeps a journal of what it did.
    final class CappedEligibilityVarianceCoordinator {
        var store: any CappedEligibilityVarianceStore
        var validator: CappedEligibilityVarianceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CappedEligibilityVarianceEngine

        init(store: any CappedEligibilityVarianceStore, validator: CappedEligibilityVarianceValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CappedEligibilityVarianceEngine) {
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
                throw Kit.Failure("capped eligibility variance \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedEligibilityVarianceStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped eligibility variance \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedEligibilityVarianceStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped eligibility variance \(code) not found")
            }
            let result = engine.run(item)
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

    static func newCappedEligibilityVarianceCoordinator(_ store: any CappedEligibilityVarianceStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CappedEligibilityVarianceCoordinator {
        return CappedEligibilityVarianceCoordinator(
            store: store,
            validator: defaultCappedEligibilityVarianceValidator(),
            clock: clock,
            journal: [],
            engine: defaultCappedEligibilityVarianceEngine(flags)
        )
    }
}
