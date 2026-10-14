import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves fallback remittance claims through their life cycle and keeps a journal of what it did.
    final class FallbackRemittanceClaimService {
        var store: any FallbackRemittanceClaimStore
        var validator: FallbackRemittanceClaimValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any FallbackRemittanceClaimStore, validator: FallbackRemittanceClaimValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("fallback remittance claim \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackRemittanceClaimStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback remittance claim \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackRemittanceClaimStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
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

    static func newFallbackRemittanceClaimService(_ store: any FallbackRemittanceClaimStore, clock: any Kit.Clocks.Clock) -> FallbackRemittanceClaimService {
        return FallbackRemittanceClaimService(
            store: store,
            validator: defaultFallbackRemittanceClaimValidator(),
            clock: clock,
            journal: []
        )
    }
}
