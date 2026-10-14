import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves lenient authorization claims through their life cycle and keeps a journal of what it did.
    final class LenientAuthorizationClaimManager {
        var store: any LenientAuthorizationClaimStore
        var validator: LenientAuthorizationClaimValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LenientAuthorizationClaimEngine

        init(store: any LenientAuthorizationClaimStore, validator: LenientAuthorizationClaimValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LenientAuthorizationClaimEngine) {
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
                throw Kit.Failure("lenient authorization claim \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientAuthorizationClaimStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient authorization claim \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientAuthorizationClaimStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient authorization claim \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newLenientAuthorizationClaimManager(_ store: any LenientAuthorizationClaimStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> LenientAuthorizationClaimManager {
        return LenientAuthorizationClaimManager(
            store: store,
            validator: defaultLenientAuthorizationClaimValidator(),
            clock: clock,
            journal: [],
            engine: defaultLenientAuthorizationClaimEngine(flags)
        )
    }
}
