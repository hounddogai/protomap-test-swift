import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves fallback claim exceptions through their life cycle and keeps a journal of what it did.
    final class FallbackClaimExceptionDesk {
        var store: any FallbackClaimExceptionStore
        var validator: FallbackClaimExceptionValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FallbackClaimExceptionEngine

        init(store: any FallbackClaimExceptionStore, validator: FallbackClaimExceptionValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FallbackClaimExceptionEngine) {
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
                throw Kit.Failure("fallback claim exception \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackClaimExceptionStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback claim exception \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackClaimExceptionStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback claim exception \(code) not found")
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

    static func newFallbackClaimExceptionDesk(_ store: any FallbackClaimExceptionStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> FallbackClaimExceptionDesk {
        return FallbackClaimExceptionDesk(
            store: store,
            validator: defaultFallbackClaimExceptionValidator(),
            clock: clock,
            journal: [],
            engine: defaultFallbackClaimExceptionEngine(flags)
        )
    }
}
