import AcmePlatform
import Foundation

extension Referrals {
    /// Moves fallback follow up baselines through their life cycle and keeps a journal of what it did.
    final class FallbackFollowUpBaselineService {
        var store: any FallbackFollowUpBaselineStore
        var validator: FallbackFollowUpBaselineValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FallbackFollowUpBaselineEngine

        init(store: any FallbackFollowUpBaselineStore, validator: FallbackFollowUpBaselineValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FallbackFollowUpBaselineEngine) {
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
                throw Kit.Failure("fallback follow up baseline \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackFollowUpBaselineStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback follow up baseline \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackFollowUpBaselineStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback follow up baseline \(code) not found")
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
                if item.createdAt > cutoff {
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

    static func newFallbackFollowUpBaselineService(_ store: any FallbackFollowUpBaselineStore, clock: any Kit.Clocks.Clock) -> FallbackFollowUpBaselineService {
        return FallbackFollowUpBaselineService(
            store: store,
            validator: defaultFallbackFollowUpBaselineValidator(),
            clock: clock,
            journal: [],
            engine: defaultFallbackFollowUpBaselineEngine()
        )
    }
}
