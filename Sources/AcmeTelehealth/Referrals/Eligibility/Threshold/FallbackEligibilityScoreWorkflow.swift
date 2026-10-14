import AcmePlatform
import Foundation

extension Referrals {
    /// Moves fallback eligibility scores through their life cycle and keeps a journal of what it did.
    final class FallbackEligibilityScoreManager {
        var store: any FallbackEligibilityScoreStore
        var validator: FallbackEligibilityScoreValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FallbackEligibilityScoreEngine

        init(store: any FallbackEligibilityScoreStore, validator: FallbackEligibilityScoreValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FallbackEligibilityScoreEngine) {
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
                throw Kit.Failure("fallback eligibility score \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackEligibilityScoreStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback eligibility score \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackEligibilityScoreStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback eligibility score \(code) not found")
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

    static func newFallbackEligibilityScoreManager(_ store: any FallbackEligibilityScoreStore, clock: any Kit.Clocks.Clock) -> FallbackEligibilityScoreManager {
        return FallbackEligibilityScoreManager(
            store: store,
            validator: defaultFallbackEligibilityScoreValidator(),
            clock: clock,
            journal: [],
            engine: defaultFallbackEligibilityScoreEngine()
        )
    }
}
