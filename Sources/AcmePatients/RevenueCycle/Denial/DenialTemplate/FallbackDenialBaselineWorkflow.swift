import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves fallback denial baselines through their life cycle and keeps a journal of what it did.
    final class FallbackDenialBaselineDesk {
        var store: any FallbackDenialBaselineStore
        var validator: FallbackDenialBaselineValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any FallbackDenialBaselineStore, validator: FallbackDenialBaselineValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("fallback denial baseline \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackDenialBaselineStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback denial baseline \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackDenialBaselineStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newFallbackDenialBaselineDesk(_ store: any FallbackDenialBaselineStore, clock: any Kit.Clocks.Clock) -> FallbackDenialBaselineDesk {
        return FallbackDenialBaselineDesk(
            store: store,
            validator: defaultFallbackDenialBaselineValidator(),
            clock: clock,
            journal: []
        )
    }
}
