import AcmePlatform
import Foundation

extension Consent {
    /// Moves fallback language claims through their life cycle and keeps a journal of what it did.
    final class FallbackLanguageClaimDesk {
        var store: any FallbackLanguageClaimStore
        var validator: FallbackLanguageClaimValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any FallbackLanguageClaimStore, validator: FallbackLanguageClaimValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("fallback language claim \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackLanguageClaimStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback language claim \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackLanguageClaimStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
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

    static func newFallbackLanguageClaimDesk(_ store: any FallbackLanguageClaimStore, clock: any Kit.Clocks.Clock) -> FallbackLanguageClaimDesk {
        return FallbackLanguageClaimDesk(
            store: store,
            validator: defaultFallbackLanguageClaimValidator(),
            clock: clock,
            journal: []
        )
    }
}
