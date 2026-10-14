import AcmePlatform
import Foundation

extension Consent {
    /// Moves fallback revocation preferences through their life cycle and keeps a journal of what it did.
    final class FallbackRevocationPreferenceService {
        var store: any FallbackRevocationPreferenceStore
        var validator: FallbackRevocationPreferenceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any FallbackRevocationPreferenceStore, validator: FallbackRevocationPreferenceValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback revocation preference \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackRevocationPreferenceStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback revocation preference \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackRevocationPreferenceStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newFallbackRevocationPreferenceService(_ store: any FallbackRevocationPreferenceStore, clock: any Kit.Clocks.Clock) -> FallbackRevocationPreferenceService {
        return FallbackRevocationPreferenceService(
            store: store,
            validator: defaultFallbackRevocationPreferenceValidator(),
            clock: clock,
            journal: []
        )
    }
}
