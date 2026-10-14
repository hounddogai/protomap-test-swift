import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves fallback denial rules through their life cycle and keeps a journal of what it did.
    final class FallbackDenialRuleManager {
        var store: any FallbackDenialRuleStore
        var validator: FallbackDenialRuleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any FallbackDenialRuleStore, validator: FallbackDenialRuleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback denial rule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackDenialRuleStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback denial rule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackDenialRuleStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
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

    static func newFallbackDenialRuleManager(_ store: any FallbackDenialRuleStore, clock: any Kit.Clocks.Clock) -> FallbackDenialRuleManager {
        return FallbackDenialRuleManager(
            store: store,
            validator: defaultFallbackDenialRuleValidator(),
            clock: clock,
            journal: []
        )
    }
}
