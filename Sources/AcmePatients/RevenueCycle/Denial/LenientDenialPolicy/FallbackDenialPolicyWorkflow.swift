import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves fallback denial policies through their life cycle and keeps a journal of what it did.
    final class FallbackDenialPolicyManager {
        var store: any FallbackDenialPolicyStore
        var validator: FallbackDenialPolicyValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any FallbackDenialPolicyStore, validator: FallbackDenialPolicyValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback denial policy \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackDenialPolicyStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback denial policy \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackDenialPolicyStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newFallbackDenialPolicyManager(_ store: any FallbackDenialPolicyStore, clock: any Kit.Clocks.Clock) -> FallbackDenialPolicyManager {
        return FallbackDenialPolicyManager(
            store: store,
            validator: defaultFallbackDenialPolicyValidator(),
            clock: clock,
            journal: []
        )
    }
}
