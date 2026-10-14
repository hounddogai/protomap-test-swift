import AcmePlatform
import Foundation

extension Consent {
    /// Moves fallback revocation tiers through their life cycle and keeps a journal of what it did.
    final class FallbackRevocationTierService {
        var store: any FallbackRevocationTierStore
        var validator: FallbackRevocationTierValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FallbackRevocationTierEngine

        init(store: any FallbackRevocationTierStore, validator: FallbackRevocationTierValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FallbackRevocationTierEngine) {
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
                throw Kit.Failure("fallback revocation tier \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackRevocationTierStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback revocation tier \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackRevocationTierStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback revocation tier \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newFallbackRevocationTierService(_ store: any FallbackRevocationTierStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> FallbackRevocationTierService {
        return FallbackRevocationTierService(
            store: store,
            validator: defaultFallbackRevocationTierValidator(),
            clock: clock,
            journal: [],
            engine: defaultFallbackRevocationTierEngine(flags)
        )
    }
}
